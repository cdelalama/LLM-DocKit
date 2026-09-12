#!/bin/sh
# dockit-sync.sh -- Sync LLM-DocKit template files to downstream projects.
# Reads dockit-sync-manifest.yml for file strategies.
#
# Usage: scripts/dockit-sync.sh [options]
#
# Options:
#   --dry-run          Show changes without applying (DEFAULT)
#   --apply            Apply changes
#   --init-state       Bootstrap: adopt current state as baseline
#   --project PATH     Sync a single project
#   --all              Sync all .dockit-enabled projects
#   --src-root PATH    Root directory for projects (default: ~/src)
#   --only SELECTOR    Sync only a manifest path or path:section (repeatable)
#   --force            Overwrite even with conflicts
#   --git-branch       Create git branch before applying
#   --json             Report in JSON format
#   --restore TS       Restore backup by timestamp
#
# This script runs ONLY from LLM-DocKit root. It is NOT copied to downstream.

set -e

# ============================================================================
# Constants
# ============================================================================

SYNC_TOOL_VERSION="1.1.0"
SUPPORTED_SCHEMA_VERSION="1"
DOCKIT_DIR_NAME=".dockit"

# ============================================================================
# Globals (set during init)
# ============================================================================

DOCKIT_ROOT=""
MANIFEST=""
TEMPLATE_VERSION=""
TEMPLATE_REF=""

# Mode flags
MODE="dry-run"           # dry-run | apply | init-state | restore
PROJECT_PATH=""
SYNC_ALL=false
SRC_ROOT="$HOME/src"
FORCE=false
GIT_BRANCH=false
JSON_OUTPUT=false
RESTORE_TS=""
ONLY_SELECTORS=""

# Runtime
TMPDIR=""
LOCK_PATH=""
BACKUP_DIR=""
BACKUP_MANIFEST=""
HAS_CONFLICTS=false
CURRENT_PROJECT=""
LOCK_ERROR_DETAIL=""

# Counters (per-project, reset in sync_project)
COUNT_UPDATED=0
COUNT_NEW=0
COUNT_SKIPPED=0
COUNT_CONFLICT=0
COUNT_ERROR=0

# Global exit code (accumulates across --all)
GLOBAL_EXIT=0

# JSON accumulator (newline-separated lines)
JSON_ENTRIES=""

# ============================================================================
# Utility functions
# ============================================================================

die() {
    echo "ERROR: $*" >&2
    exit 1
}

warn() {
    echo "WARN: $*" >&2
}

info() {
    if ! $JSON_OUTPUT; then
        echo "$*"
    fi
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

append_only_selector() {
    _selector="$1"
    if [ -z "$ONLY_SELECTORS" ]; then
        ONLY_SELECTORS="$_selector"
    else
        ONLY_SELECTORS="$ONLY_SELECTORS
$_selector"
    fi
}

# Return success when a manifest path is in the selected scope. A whole-file
# selector and any path:section selector both select the manifest entry.
entry_is_selected() {
    _relpath="$1"
    [ -z "$ONLY_SELECTORS" ] && return 0

    while IFS= read -r _selector; do
        [ "$_selector" = "$_relpath" ] && return 0
        case "$_selector" in
            "$_relpath":*) return 0 ;;
        esac
    done <<EOF
$ONLY_SELECTORS
EOF
    return 1
}

# Return success only for an exact whole-file selector.
path_is_selected_as_whole() {
    _relpath="$1"
    [ -z "$ONLY_SELECTORS" ] && return 0

    while IFS= read -r _selector; do
        [ "$_selector" = "$_relpath" ] && return 0
    done <<EOF
$ONLY_SELECTORS
EOF
    return 1
}

# Return success when a section is selected directly or through its whole file.
section_is_selected() {
    _relpath="$1"
    _section_id="$2"
    [ -z "$ONLY_SELECTORS" ] && return 0

    while IFS= read -r _selector; do
        [ "$_selector" = "$_relpath" ] && return 0
        [ "$_selector" = "$_relpath:$_section_id" ] && return 0
    done <<EOF
$ONLY_SELECTORS
EOF
    return 1
}

# Validate every selector against the current manifest before touching any
# downstream project. Section selectors are valid only for section-merge files.
validate_only_selectors() {
    [ -z "$ONLY_SELECTORS" ] && return 0

    if [ "$MODE" = "init-state" ] || [ "$MODE" = "restore" ]; then
        die "--only cannot be combined with --$MODE"
    fi

    _selector_entries="$TMPDIR/selector_entries.txt"
    parse_manifest "$MANIFEST" "$_selector_entries"

    while IFS= read -r _selector; do
        [ -n "$_selector" ] || die "--only requires a non-empty selector"

        case "$_selector" in
            *:*)
                _selector_path=${_selector%%:*}
                _selector_section=${_selector#*:}
                [ -n "$_selector_path" ] && [ -n "$_selector_section" ] || \
                    die "Invalid --only selector: $_selector"
                _selector_strategy=$(awk -v path="$_selector_path" '$1 == path { print $2; exit }' "$_selector_entries")
                [ -n "$_selector_strategy" ] || die "Unknown --only path: $_selector_path"
                [ "$_selector_strategy" = "section-merge" ] || \
                    die "Section selector requires section-merge strategy: $_selector"
                grep -qxF "<!-- DOCKIT-TEMPLATE:START $_selector_section -->" \
                    "$DOCKIT_ROOT/$_selector_path" 2>/dev/null || \
                    die "Unknown --only section: $_selector"
                ;;
            *)
                _selector_strategy=$(awk -v path="$_selector" '$1 == path { print $2; exit }' "$_selector_entries")
                [ -n "$_selector_strategy" ] || die "Unknown --only path: $_selector"
                [ "$_selector_strategy" != "skip" ] || \
                    die "--only cannot select a project-specific skip path: $_selector"
                ;;
        esac
    done <<EOF
$ONLY_SELECTORS
EOF
}

# Detect hash command (sha256sum or shasum -a 256)
detect_hash_cmd() {
    if command -v sha256sum >/dev/null 2>&1; then
        HASH_CMD="sha256sum"
    elif command -v shasum >/dev/null 2>&1; then
        HASH_CMD="shasum -a 256"
    else
        die "No sha256 hash command found (need sha256sum or shasum)"
    fi
}

# Canonical hash: strip CR, trailing whitespace, trailing newlines, then hash
normalize_and_hash() {
    tr -d '\r' | sed 's/[[:space:]]*$//' | awk 'NR>1{print prev} {prev=$0} END{if(NR>0) printf "%s", prev}' | $HASH_CMD | awk '{print $1}'
}

# Hash a file with normalization
hash_file() {
    normalize_and_hash < "$1"
}

# ============================================================================
# Manifest lint and parse
# ============================================================================

lint_manifest() {
    _manifest="$1"

    # Reject tabs
    if awk '/\t/ { found=1; exit } END { exit !found }' "$_manifest" 2>/dev/null; then
        die "Manifest contains tabs (only spaces allowed): $_manifest"
    fi

    # Validate schema_version is present and supported
    _schema=$(grep '^schema_version:' "$_manifest" 2>/dev/null | head -1 | sed 's/^schema_version:[[:space:]]*//' | tr -d '[:space:]')
    if [ -z "$_schema" ]; then
        die "Manifest missing schema_version: $_manifest"
    fi
    if [ "$_schema" != "$SUPPORTED_SCHEMA_VERSION" ]; then
        die "Unsupported schema_version: $_schema (expected: $SUPPORTED_SCHEMA_VERSION)"
    fi

    # Validate entry format (tolerant of leading whitespace)
    _entry_regex='^[[:space:]]*-[[:space:]]*path:[[:space:]]*[^[:space:]]+[[:space:]]+strategy:[[:space:]]*(copy|skip|section-merge|yaml-merge)[[:space:]]*$'
    _lint_errors=""
    _lint_tmpfile="$TMPDIR/lint_entries.txt"
    grep '^[[:space:]]*-[[:space:]]*path:' "$_manifest" > "$_lint_tmpfile" || true
    while IFS= read -r _line; do
        if ! echo "$_line" | grep -qE "$_entry_regex"; then
            _lint_errors="${_lint_errors}  Invalid entry: $_line
"
        fi
    done < "$_lint_tmpfile"
    if [ -n "$_lint_errors" ]; then
        die "Manifest lint errors in $_manifest:
$_lint_errors"
    fi

    # Reject duplicate paths
    _dups=$(grep '^[[:space:]]*-[[:space:]]*path:' "$_manifest" | \
        sed 's/^[[:space:]]*-[[:space:]]*path:[[:space:]]*//' | \
        sed 's/[[:space:]]*strategy:.*//' | sort | uniq -d)
    if [ -n "$_dups" ]; then
        die "Duplicate paths in manifest: $_dups"
    fi
}

# Parse manifest into tmpfile: "path strategy" per line
parse_manifest() {
    _manifest="$1"
    _output="$2"
    grep '^[[:space:]]*-[[:space:]]*path:' "$_manifest" | \
        sed 's/^[[:space:]]*-[[:space:]]*path:[[:space:]]*//' | \
        sed 's/[[:space:]]*strategy:[[:space:]]*/\t/' | \
        sed 's/[[:space:]]*$//' | \
        tr '\t' ' ' > "$_output"
}

# ============================================================================
# Lock management
# ============================================================================

acquire_lock() {
    _project_root="$1"
    _dockit_dir="$_project_root/.git/$DOCKIT_DIR_NAME"
    _candidate_lock="$_dockit_dir/sync.lock"
    LOCK_ERROR_DETAIL=""

    if ! mkdir -p "$_dockit_dir"; then
        LOCK_ERROR_DETAIL="cannot create lock directory: $_dockit_dir"
        return 1
    fi

    if [ -f "$_candidate_lock" ]; then
        _lock_pid=$(cat "$_candidate_lock" 2>/dev/null || echo "")
        if [ -n "$_lock_pid" ] && kill -0 "$_lock_pid" 2>/dev/null; then
            LOCK_ERROR_DETAIL="locked by active PID $_lock_pid"
            return 1
        else
            warn "Stale lock found (PID: $_lock_pid not running). Removing."
            rm -f "$_candidate_lock"
        fi
    fi

    if ! echo "$$" > "$_candidate_lock"; then
        LOCK_ERROR_DETAIL="cannot write lock file: $_candidate_lock"
        return 1
    fi
    LOCK_PATH="$_candidate_lock"
}

release_lock() {
    if [ -n "$LOCK_PATH" ] && [ -f "$LOCK_PATH" ]; then
        rm -f "$LOCK_PATH"
    fi
    LOCK_PATH=""
}

# ============================================================================
# Backup and restore
# ============================================================================

# Create backup dir, returns path via BACKUP_DIR global
create_backup_dir() {
    _project_root="$1"
    _ts=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$_project_root/.git/$DOCKIT_DIR_NAME/backups/$_ts"
    mkdir -p "$BACKUP_DIR"
    BACKUP_MANIFEST="$BACKUP_DIR/backup-manifest.txt"
    : > "$BACKUP_MANIFEST"
}

# Record a file in the backup manifest and copy if it exists
backup_file() {
    _project_root="$1"
    _relpath="$2"
    _fullpath="$_project_root/$_relpath"

    if [ -f "$_fullpath" ]; then
        # File exists -> UPDATED
        _backup_dest="$BACKUP_DIR/$_relpath"
        mkdir -p "$(dirname "$_backup_dest")"
        cp -p "$_fullpath" "$_backup_dest"
        echo "UPDATED $_relpath" >> "$BACKUP_MANIFEST"
    else
        # File doesn't exist -> NEW
        echo "NEW $_relpath" >> "$BACKUP_MANIFEST"
    fi
}

# Rollback using backup manifest
rollback() {
    _project_root="$1"
    _backup_dir="$2"
    _manifest_file="$_backup_dir/backup-manifest.txt"

    if [ ! -f "$_manifest_file" ]; then
        warn "No backup manifest found at $_manifest_file"
        return 1
    fi

    info "Rolling back changes..."
    while IFS=' ' read -r _action _relpath; do
        case "$_action" in
            UPDATED)
                _src="$_backup_dir/$_relpath"
                _dst="$_project_root/$_relpath"
                if [ -f "$_src" ]; then
                    mkdir -p "$(dirname "$_dst")"
                    cp -p "$_src" "$_dst"
                    info "  Restored: $_relpath"
                else
                    warn "  Backup file missing: $_src"
                fi
                ;;
            NEW)
                _dst="$_project_root/$_relpath"
                if [ -f "$_dst" ]; then
                    rm -f "$_dst"
                    info "  Removed (was new): $_relpath"
                fi
                ;;
            *)
                warn "  Unknown backup action: $_action $_relpath"
                ;;
        esac
    done < "$_manifest_file"
    info "Rollback complete."
}

# Restore a specific backup by timestamp
restore_backup() {
    _project_root="$1"
    _timestamp="$2"
    _backup_dir="$_project_root/.git/$DOCKIT_DIR_NAME/backups/$_timestamp"

    if [ ! -d "$_backup_dir" ]; then
        warn "Backup not found: $_backup_dir"
        return 1
    fi

    rollback "$_project_root" "$_backup_dir"
}

# Keep only the 5 most recent backups
cleanup_backups() {
    _project_root="$1"
    _backups_dir="$_project_root/.git/$DOCKIT_DIR_NAME/backups"

    if [ ! -d "$_backups_dir" ]; then
        return
    fi

    # List dirs sorted newest first, remove from 6th onwards
    _count=0
    for _d in $(ls -1t "$_backups_dir" 2>/dev/null); do
        _count=$((_count + 1))
        if [ "$_count" -gt 5 ]; then
            rm -rf "$_backups_dir/$_d"
        fi
    done
}

# ============================================================================
# State management
# ============================================================================

read_state_version() {
    _state_file="$1"
    if [ -f "$_state_file" ]; then
        grep '^template_version:' "$_state_file" 2>/dev/null | head -1 | \
            sed 's/^template_version:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]'
    fi
}

read_state_ref() {
    _state_file="$1"
    if [ -f "$_state_file" ]; then
        grep '^template_ref:' "$_state_file" 2>/dev/null | head -1 | \
            sed 's/^template_ref:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]'
    fi
}

flatten_state_hashes() {
    _state_file="$1"
    _flat_file="$2"

    awk '
        /^section_hashes:[[:space:]]*$/ { in_hashes=1; next }
        in_hashes && /^  [^[:space:]][^:]*:[[:space:]]*$/ {
            current_file=$0
            sub(/^  /, "", current_file)
            sub(/:[[:space:]]*$/, "", current_file)
            next
        }
        in_hashes && /^    [^[:space:]][^:]*:[[:space:]]*/ {
            line=$0
            sub(/^    /, "", line)
            section=line
            sub(/:.*/, "", section)
            hash=line
            sub(/^[^:]*:[[:space:]]*/, "", hash)
            gsub(/\042/, "", hash)
            gsub(/\047/, "", hash)
            if (current_file != "" && section != "" && hash != "") {
                print current_file, section, hash
            }
        }
    ' "$_state_file" > "$_flat_file"
}

state_hashes_format_valid() {
    _state_file="$1"

    awk '
        /^[[:space:]]*section_hashes:/ {
            if ($0 != "section_hashes:" || seen_hashes) bad=1
            seen_hashes=1
            in_hashes=1
            next
        }
        in_hashes && /^  [^[:space:]][^:]*:[[:space:]]*$/ {
            have_file=1
            next
        }
        in_hashes && /^    [^[:space:]][^:]*:[[:space:]]*/ && have_file {
            value=$0
            sub(/^    [^:]*:[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            if (value ~ /^".*"$/) {
                sub(/^"/, "", value)
                sub(/"$/, "", value)
            } else if (value ~ /^\047.*\047$/) {
                sub(/^\047/, "", value)
                sub(/\047$/, "", value)
            }
            if (length(value) != 64 || value ~ /[^0-9a-f]/) bad=1
            else entries += 1
            next
        }
        in_hashes && /^[[:space:]]*$/ { next }
        in_hashes { bad=1 }
        END {
            if (seen_hashes && entries == 0) bad=1
            exit bad
        }
    ' "$_state_file"
}

# Read a section hash from state.yml
# Usage: read_section_hash state_file filename section_id
read_section_hash() {
    _state_file="$1"
    _filename="$2"
    _section_id="$3"

    if [ ! -f "$_state_file" ]; then
        return
    fi

    # Simple line-based parse: look for "    section_id: hash" after "  filename:"
    _in_file=false
    while IFS= read -r _line; do
        case "$_line" in
            *"$_filename:"*)
                _in_file=true
                ;;
            *":"*)
                if $_in_file; then
                    _key=$(echo "$_line" | sed 's/^[[:space:]]*//' | sed 's/:.*//')
                    _val=$(echo "$_line" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'")
                    if [ "$_key" = "$_section_id" ]; then
                        echo "$_val"
                        return
                    fi
                    # If we hit a non-indented key, we left the file section
                    case "$_line" in
                        "  "*)  ;;  # still indented, continue
                        *)  _in_file=false ;;
                    esac
                fi
                ;;
        esac
    done < "$_state_file"
}

write_state() {
    _project_root="$1"
    _mode="$2"
    _section_hashes_file="$3"  # optional: tmpfile with "filename section_id hash" lines

    _state_file="$_project_root/.git/$DOCKIT_DIR_NAME/state.yml"
    mkdir -p "$(dirname "$_state_file")"

    _now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

    _state_tmp="$TMPDIR/state_new.yml"
    cat > "$_state_tmp" <<STATEEOF
# .git/.dockit/state.yml -- auto-generated by dockit-sync.sh. Do not edit.
template_version: "$TEMPLATE_VERSION"
template_ref: "$TEMPLATE_REF"
last_sync_at: "$_now"
last_sync_mode: "$_mode"
sync_tool_version: "$SYNC_TOOL_VERSION"
STATEEOF

    # Append section hashes if provided
    if [ -n "$_section_hashes_file" ] && [ -f "$_section_hashes_file" ] && [ -s "$_section_hashes_file" ]; then
        echo "section_hashes:" >> "$_state_tmp"
        _current_file=""
        while IFS=' ' read -r _sf _sid _shash; do
            if [ "$_sf" != "$_current_file" ]; then
                echo "  $_sf:" >> "$_state_tmp"
                _current_file="$_sf"
            fi
            echo "    $_sid: \"$_shash\"" >> "$_state_tmp"
        done < "$_section_hashes_file"
    fi

    cp "$_state_tmp" "$_state_file"
}

# Merge selected section baselines while preserving the adopter's full-template
# identity. This prevents a narrow policy rollout from claiming full currency
# without sacrificing future conflict detection for the section just applied.
write_state_selective() {
    _project_root="$1"
    _selected_hashes_file="$2"
    _state_file="$_project_root/.git/$DOCKIT_DIR_NAME/state.yml"

    if [ ! -f "$_state_file" ]; then
        warn "Selective state merge requires an existing state file: $_state_file"
        return 1
    fi
    [ -s "$_selected_hashes_file" ] || return 0

    if ! state_hashes_format_valid "$_state_file"; then
        warn "Selective state merge rejected malformed section_hashes in $_state_file"
        return 1
    fi

    _preserved_version=$(read_state_version "$_state_file")
    _preserved_ref=$(read_state_ref "$_state_file")
    if [ -z "$_preserved_version" ] || [ -z "$_preserved_ref" ]; then
        warn "Selective state merge requires template_version and template_ref in $_state_file"
        return 1
    fi

    _existing_hashes="$TMPDIR/state_existing_hashes.txt"
    _merged_hashes="$TMPDIR/state_merged_hashes.txt"
    flatten_state_hashes "$_state_file" "$_existing_hashes"
    cp "$_existing_hashes" "$_merged_hashes"

    while IFS=' ' read -r _sf _sid _shash; do
        _merge_tmp="$TMPDIR/state_hash_merge.tmp"
        awk -v file="$_sf" -v section="$_sid" -v hash="$_shash" '
            $1 == file && $2 == section {
                print file, section, hash
                replaced=1
                next
            }
            { print }
            END {
                if (!replaced) print file, section, hash
            }
        ' "$_merged_hashes" > "$_merge_tmp"
        mv "$_merge_tmp" "$_merged_hashes"
    done < "$_selected_hashes_file"

    LC_ALL=C sort -k1,1 -k2,2 "$_merged_hashes" > "$_merged_hashes.sorted"
    mv "$_merged_hashes.sorted" "$_merged_hashes"

    _now=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)
    _state_tmp="$TMPDIR/state_selective_new.yml"
    cat > "$_state_tmp" <<STATEEOF
# .git/.dockit/state.yml -- auto-generated by dockit-sync.sh. Do not edit.
template_version: "$_preserved_version"
template_ref: "$_preserved_ref"
last_sync_at: "$_now"
last_sync_mode: "apply-selective"
sync_tool_version: "$SYNC_TOOL_VERSION"
STATEEOF

    if [ -s "$_merged_hashes" ]; then
        echo "section_hashes:" >> "$_state_tmp"
        _current_file=""
        while IFS=' ' read -r _sf _sid _shash; do
            if [ "$_sf" != "$_current_file" ]; then
                echo "  $_sf:" >> "$_state_tmp"
                _current_file="$_sf"
            fi
            echo "    $_sid: \"$_shash\"" >> "$_state_tmp"
        done < "$_merged_hashes"
    fi

    cp "$_state_tmp" "$_state_file"
}

# ============================================================================
# Config reading (.dockit-config.yml)
# ============================================================================

# Read adoption_mode from .dockit-config.yml (default: full)
read_adoption_mode() {
    _config_file="$1/.dockit-config.yml"
    if [ -f "$_config_file" ]; then
        _mode=$(grep '^adoption_mode:' "$_config_file" 2>/dev/null | head -1 | \
            sed 's/^adoption_mode:[[:space:]]*//' | tr -d '[:space:]')
        if [ -n "$_mode" ]; then
            echo "$_mode"
            return
        fi
    fi
    echo "full"
}

# Check if a section is excluded for a file
# Usage: is_section_excluded project_root filename section_id
is_section_excluded() {
    _config_file="$1/.dockit-config.yml"
    _filename="$2"
    _section_id="$3"

    if [ ! -f "$_config_file" ]; then
        return 1  # not excluded
    fi

    # Simple parse: find lines after "  filename:" that contain "- section_id"
    _in_file=false
    while IFS= read -r _line; do
        case "$_line" in
            *"$_filename:"*)
                _in_file=true
                ;;
            *"- $_section_id"*)
                if $_in_file; then
                    return 0  # excluded
                fi
                ;;
            *":"*)
                if $_in_file; then
                    # Check if this is still indented (part of the list) or a new key
                    case "$_line" in
                        "    -"*)  ;;  # list item, continue
                        "  "*)  _in_file=false ;;  # new file key
                        *)  _in_file=false ;;
                    esac
                fi
                ;;
        esac
    done < "$_config_file"
    return 1  # not excluded
}

# ============================================================================
# Report functions
# ============================================================================

report_entry() {
    _file="$1"
    _status="$2"
    _detail="$3"

    if $JSON_OUTPUT; then
        _json_project=$(json_escape "$CURRENT_PROJECT")
        _json_file=$(json_escape "$_file")
        _json_status=$(json_escape "$_status")
        _json_detail=$(json_escape "$_detail")
        _json_line="{\"project\": \"$_json_project\", \"file\": \"$_json_file\", \"status\": \"$_json_status\", \"detail\": \"$_json_detail\"}"
        if [ -z "$JSON_ENTRIES" ]; then
            JSON_ENTRIES="$_json_line"
        else
            JSON_ENTRIES="$JSON_ENTRIES
$_json_line"
        fi
    else
        printf "  %-40s %-10s %s\n" "$_file" "$_status" "$_detail"
    fi

    case "$_status" in
        UPDATED)  COUNT_UPDATED=$((COUNT_UPDATED + 1)) ;;
        NEW)      COUNT_NEW=$((COUNT_NEW + 1)) ;;
        SKIPPED)  COUNT_SKIPPED=$((COUNT_SKIPPED + 1)) ;;
        CONFLICT) COUNT_CONFLICT=$((COUNT_CONFLICT + 1)) ;;
        ERROR)    COUNT_ERROR=$((COUNT_ERROR + 1)) ;;
    esac
}

print_summary() {
    if ! $JSON_OUTPUT; then
        echo ""
        echo "Summary: $COUNT_UPDATED updated, $COUNT_NEW new, $COUNT_SKIPPED skipped, $COUNT_CONFLICT conflicts, $COUNT_ERROR errors"
    fi
}

print_json_report() {
    echo "["
    if [ -n "$JSON_ENTRIES" ]; then
        printf '%s\n' "$JSON_ENTRIES" | awk '
            NR == 1 { print "  " $0; next }
            { print "  ," $0 }
        '
    fi
    echo "]"
}

# ============================================================================
# Sync strategies
# ============================================================================

normalize_project_doc_version() {
    _project_root="$1"
    _relpath="$2"
    _target_file="$_project_root/$_relpath"
    _version_file="$_project_root/VERSION"

    [ -f "$_target_file" ] || return 0
    [ -f "$_version_file" ] || return 0
    grep -q '<!-- doc-version:' "$_target_file" 2>/dev/null || return 0

    _project_version=$(head -1 "$_version_file" | tr -d '[:space:]')
    echo "$_project_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || return 0

    _tmp_normalized=$(mktemp)
    sed "s/<!-- doc-version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* -->/<!-- doc-version: $_project_version -->/" \
        "$_target_file" > "$_tmp_normalized"
    if cmp -s "$_target_file" "$_tmp_normalized"; then
        rm -f "$_tmp_normalized"
    else
        cat "$_tmp_normalized" > "$_target_file"
        rm -f "$_tmp_normalized"
    fi
}

# Copy strategy: overwrite downstream with template version
sync_copy() {
    _project_root="$1"
    _relpath="$2"
    _template_file="$DOCKIT_ROOT/$_relpath"
    _downstream_file="$_project_root/$_relpath"

    if [ ! -f "$_template_file" ]; then
        report_entry "$_relpath" "ERROR" "template file not found"
        return
    fi

    if [ ! -f "$_downstream_file" ]; then
        # New file
        if [ "$MODE" = "apply" ]; then
            backup_file "$_project_root" "$_relpath"
            mkdir -p "$(dirname "$_downstream_file")"
            cp -p "$_template_file" "$_downstream_file"
            normalize_project_doc_version "$_project_root" "$_relpath"
        fi
        report_entry "$_relpath" "NEW" "will be created from template"
        return
    fi

    # Compare hashes
    _tmpl_hash=$(hash_file "$_template_file")
    _down_hash=$(hash_file "$_downstream_file")

    if [ "$_tmpl_hash" = "$_down_hash" ]; then
        report_entry "$_relpath" "SKIPPED" "already up to date"
        return
    fi

    # Different -> update
    if [ "$MODE" = "apply" ]; then
        backup_file "$_project_root" "$_relpath"
        cp -p "$_template_file" "$_downstream_file"
        normalize_project_doc_version "$_project_root" "$_relpath"
    fi
    report_entry "$_relpath" "UPDATED" "template changed"
}

# Section-merge strategy: replace content between DOCKIT-TEMPLATE markers
sync_section_merge() {
    _project_root="$1"
    _relpath="$2"
    _template_file="$DOCKIT_ROOT/$_relpath"
    _downstream_file="$_project_root/$_relpath"
    _state_file="$_project_root/.git/$DOCKIT_DIR_NAME/state.yml"
    _adoption_mode=$(read_adoption_mode "$_project_root")

    if [ ! -f "$_template_file" ]; then
        report_entry "$_relpath" "ERROR" "template file not found"
        return
    fi

    if [ ! -f "$_downstream_file" ]; then
        if [ -n "$ONLY_SELECTORS" ] && ! path_is_selected_as_whole "$_relpath"; then
            report_entry "$_relpath" "ERROR" "cannot create a missing file from a section-only selector"
            return
        fi
        # No downstream file: copy entire template
        if [ "$MODE" = "apply" ]; then
            backup_file "$_project_root" "$_relpath"
            mkdir -p "$(dirname "$_downstream_file")"
            cp -p "$_template_file" "$_downstream_file"
        fi
        report_entry "$_relpath" "NEW" "will be created from template"

        _new_sids="$TMPDIR/new_file_sections.txt"
        grep '<!-- DOCKIT-TEMPLATE:START ' "$_template_file" 2>/dev/null | \
            sed 's/.*<!-- DOCKIT-TEMPLATE:START //' | sed 's/ -->.*//' > "$_new_sids" || true
        while IFS= read -r _sid; do
            _start_marker="<!-- DOCKIT-TEMPLATE:START $_sid -->"
            _end_marker="<!-- DOCKIT-TEMPLATE:END $_sid -->"
            _new_content="$TMPDIR/new_file_${_sid}.txt"
            awk -v start="$_start_marker" -v end="$_end_marker" '
                $0 == start { capture=1; next }
                $0 == end   { capture=0; next }
                capture { print }
            ' "$_template_file" > "$_new_content"
            _new_hash=$(hash_file "$_new_content")
            echo "$_relpath $_sid $_new_hash" >> "$TMPDIR/all_section_hashes.txt"
        done < "$_new_sids"
        return
    fi

    # Get section IDs from template
    _tmpl_sections="$TMPDIR/tmpl_sections.txt"
    grep '<!-- DOCKIT-TEMPLATE:START ' "$_template_file" 2>/dev/null | \
        sed 's/.*<!-- DOCKIT-TEMPLATE:START //' | sed 's/ -->.*//' > "$_tmpl_sections" || true

    if [ ! -s "$_tmpl_sections" ]; then
        report_entry "$_relpath" "SKIPPED" "no template markers found"
        return
    fi

    # Check for unknown IDs in downstream (not in template)
    _down_sections="$TMPDIR/down_sections.txt"
    grep '<!-- DOCKIT-TEMPLATE:START ' "$_downstream_file" 2>/dev/null | \
        sed 's/.*<!-- DOCKIT-TEMPLATE:START //' | sed 's/ -->.*//' > "$_down_sections" || true

    if [ -z "$ONLY_SELECTORS" ] || path_is_selected_as_whole "$_relpath"; then
        while IFS= read -r _dsid; do
            if ! grep -qx "$_dsid" "$_tmpl_sections"; then
                if is_section_excluded "$_project_root" "$_relpath" "$_dsid"; then
                    continue
                fi
                if [ "$_adoption_mode" = "full" ]; then
                    report_entry "$_relpath" "ERROR" "unknown section in downstream: $_dsid"
                    return
                else
                    warn "Unknown section in downstream $_relpath: $_dsid"
                fi
            fi
        done < "$_down_sections"
    fi

    # Process each template section
    _file_changed=false
    _working_file="$TMPDIR/section_merge_work.md"
    cp "$_downstream_file" "$_working_file"
    _hashes_file="$TMPDIR/section_hashes.txt"
    : > "$_hashes_file"

    while IFS= read -r _sid; do
        if ! section_is_selected "$_relpath" "$_sid"; then
            continue
        fi

        # Check exclusion
        if is_section_excluded "$_project_root" "$_relpath" "$_sid"; then
            if [ -n "$ONLY_SELECTORS" ]; then
                report_entry "$_relpath:$_sid" "SKIPPED" "excluded by .dockit-config.yml"
            fi
            continue
        fi

        _start_marker="<!-- DOCKIT-TEMPLATE:START $_sid -->"
        _end_marker="<!-- DOCKIT-TEMPLATE:END $_sid -->"

        # Extract template section content/block once. Missing-section handling
        # for full adopters uses the full block, including markers, to onboard
        # newly-added template sections into older downstream files.
        _tmpl_content="$TMPDIR/tmpl_${_sid}.txt"
        awk -v start="$_start_marker" -v end="$_end_marker" '
            $0 == start { capture=1; next }
            $0 == end   { capture=0; next }
            capture { print }
        ' "$_template_file" > "$_tmpl_content"

        _tmpl_block="$TMPDIR/tmpl_block_${_sid}.txt"
        awk -v start="$_start_marker" -v end="$_end_marker" '
            $0 == start { capture=1 }
            capture { print }
            $0 == end { capture=0 }
        ' "$_template_file" > "$_tmpl_block"

        _tmpl_hash=$(hash_file "$_tmpl_content")

        # Check markers exist in downstream
        _start_count=$(grep -c "^$_start_marker$" "$_working_file" 2>/dev/null) || true
        _end_count=$(grep -c "^$_end_marker$" "$_working_file" 2>/dev/null) || true

        if [ "$_start_count" = "0" ] || [ "$_end_count" = "0" ]; then
            if [ "$_start_count" = "0" ] && [ "$_end_count" = "0" ] && [ "$_adoption_mode" = "full" ]; then
                _inserted="$TMPDIR/section_inserted_${_sid}.md"
                _footer_marker="<!-- DOCKIT-TEMPLATE:START footer -->"

                if [ "$_sid" != "footer" ] && grep -q "^$_footer_marker$" "$_working_file" 2>/dev/null; then
                    awk -v marker="$_footer_marker" -v bfile="$_tmpl_block" '
                        $0 == marker && !inserted {
                            while ((getline l < bfile) > 0) print l
                            close(bfile)
                            print ""
                            inserted = 1
                        }
                        { print }
                    ' "$_working_file" > "$_inserted"
                else
                    {
                        cat "$_working_file"
                        printf '\n'
                        cat "$_tmpl_block"
                    } > "$_inserted"
                fi

                cp "$_inserted" "$_working_file"
                echo "$_relpath $_sid $_tmpl_hash" >> "$_hashes_file"
                _file_changed=true
                if [ -n "$ONLY_SELECTORS" ]; then
                    report_entry "$_relpath:$_sid" "UPDATED" "section inserted"
                fi
                continue
            fi

            if [ "$_adoption_mode" = "full" ]; then
                report_entry "$_relpath" "ERROR" "malformed markers for section: $_sid"
                return
            else
                if [ -n "$ONLY_SELECTORS" ]; then
                    report_entry "$_relpath:$_sid" "SKIPPED" "no markers (partial adopter)"
                else
                    warn "Missing markers for section $_sid in $_relpath (partial mode: skipping)"
                fi
                continue
            fi
        fi

        if [ "$_start_count" != "1" ] || [ "$_end_count" != "1" ]; then
            report_entry "$_relpath" "ERROR" "duplicate markers for section: $_sid"
            return
        fi

        # Extract content between markers from downstream
        _down_content="$TMPDIR/down_${_sid}.txt"
        awk -v start="$_start_marker" -v end="$_end_marker" '
            $0 == start { capture=1; next }
            $0 == end   { capture=0; next }
            capture { print }
        ' "$_working_file" > "$_down_content"

        # Compute hashes
        _down_hash=$(hash_file "$_down_content")

        # Record hash for state
        echo "$_relpath $_sid $_tmpl_hash" >> "$_hashes_file"

        # Already in sync?
        if [ "$_tmpl_hash" = "$_down_hash" ]; then
            if [ -n "$ONLY_SELECTORS" ]; then
                report_entry "$_relpath:$_sid" "SKIPPED" "section already current"
            fi
            continue
        fi

        # Conflict detection
        _stored_hash=$(read_section_hash "$_state_file" "$_relpath" "$_sid")

        if [ -n "$_stored_hash" ]; then
            # We have a baseline. Check if downstream was locally modified
            if [ "$_down_hash" != "$_stored_hash" ] && [ "$_down_hash" != "$_tmpl_hash" ]; then
                # Downstream changed AND template changed -> CONFLICT
                if ! $FORCE; then
                    HAS_CONFLICTS=true
                    report_entry "$_relpath:$_sid" "CONFLICT" "local and template both changed"
                    continue
                fi
                warn "Forcing update of conflicting section: $_sid in $_relpath"
            fi
        fi

        # Replace section content in working file
        _replaced="$TMPDIR/section_replaced.md"
        awk -v start="$_start_marker" -v end="$_end_marker" -v tfile="$_tmpl_content" '
            $0 == start { print; while ((getline l < tfile) > 0) print l; close(tfile); skip=1; next }
            $0 == end   { skip=0; print; next }
            !skip { print }
        ' "$_working_file" > "$_replaced"
        cp "$_replaced" "$_working_file"
        _file_changed=true
        if [ -n "$ONLY_SELECTORS" ]; then
            report_entry "$_relpath:$_sid" "UPDATED" "section merged"
        fi

    done < "$_tmpl_sections"

    # Apply changes if file was modified
    if $_file_changed; then
        if [ "$MODE" = "apply" ]; then
            backup_file "$_project_root" "$_relpath"
            cp "$_working_file" "$_downstream_file"
        fi
        if [ -z "$ONLY_SELECTORS" ]; then
            report_entry "$_relpath" "UPDATED" "sections merged"
        fi
    else
        if [ -n "$ONLY_SELECTORS" ]; then
            : # selected sections reported individually
        elif [ "$COUNT_CONFLICT" -gt 0 ]; then
            : # conflicts already reported per-section
        else
            report_entry "$_relpath" "SKIPPED" "all sections up to date"
        fi
    fi

    # Save hashes for state writing
    if [ -s "$_hashes_file" ]; then
        cat "$_hashes_file" >> "$TMPDIR/all_section_hashes.txt"
    fi
}

# YAML-merge strategy for version-sync-manifest.yml
sync_yaml_merge() {
    _project_root="$1"
    _relpath="$2"
    _template_file="$DOCKIT_ROOT/$_relpath"
    _downstream_file="$_project_root/$_relpath"

    if [ ! -f "$_template_file" ]; then
        report_entry "$_relpath" "ERROR" "template file not found"
        return
    fi

    if [ ! -f "$_downstream_file" ]; then
        if [ "$MODE" = "apply" ]; then
            backup_file "$_project_root" "$_relpath"
            mkdir -p "$(dirname "$_downstream_file")"
            cp -p "$_template_file" "$_downstream_file"
        fi
        report_entry "$_relpath" "NEW" "will be created from template"
        return
    fi

    # Parse template entries (path as identity key)
    _tmpl_entries="$TMPDIR/yaml_tmpl.txt"
    grep '^[[:space:]]*-[[:space:]]*path:' "$_template_file" | \
        sed 's/^[[:space:]]*-[[:space:]]*path:[[:space:]]*//' > "$_tmpl_entries" || true

    # Parse downstream entries
    _down_entries="$TMPDIR/yaml_down.txt"
    grep '^[[:space:]]*-[[:space:]]*path:' "$_downstream_file" | \
        sed 's/^[[:space:]]*-[[:space:]]*path:[[:space:]]*//' > "$_down_entries" || true

    # Extract template paths for comparison
    _tmpl_paths="$TMPDIR/yaml_tmpl_paths.txt"
    sed 's/[[:space:]]*marker:.*//' "$_tmpl_entries" > "$_tmpl_paths"

    # Build merged file
    _merged="$TMPDIR/yaml_merged.yml"

    # Preserve downstream header (everything up to and including "targets:")
    awk '/^targets:/ { print; exit } { print }' "$_downstream_file" > "$_merged"

    # Write all template entries
    while IFS= read -r _entry; do
        echo "- path: $_entry" >> "$_merged"
    done < "$_tmpl_entries"

    # Find downstream-only entries (paths not in template)
    _has_local=false
    while IFS= read -r _dentry; do
        _dpath=$(echo "$_dentry" | sed 's/[[:space:]]*marker:.*//')
        if ! grep -qx "$_dpath" "$_tmpl_paths"; then
            if ! $_has_local; then
                echo "# --- Project-specific entries (preserved by dockit-sync) ---" >> "$_merged"
                _has_local=true
            fi
            echo "- path: $_dentry" >> "$_merged"
        fi
    done < "$_down_entries"

    # Ensure trailing newline
    echo "" >> "$_merged"

    # Compare result with current downstream
    _merged_hash=$(hash_file "$_merged")
    _down_hash=$(hash_file "$_downstream_file")

    if [ "$_merged_hash" = "$_down_hash" ]; then
        report_entry "$_relpath" "SKIPPED" "already up to date"
        return
    fi

    if [ "$MODE" = "apply" ]; then
        backup_file "$_project_root" "$_relpath"
        cp "$_merged" "$_downstream_file"
    fi
    report_entry "$_relpath" "UPDATED" "entries merged"
}

# ============================================================================
# Post-sync validation
# ============================================================================

validate_project() {
    _project_root="$1"
    _validation_phase=${2:-post-sync}

    # Gating: all 3 prerequisites must exist
    if [ ! -x "$_project_root/scripts/check-version-sync.sh" ]; then
        warn "Skipping $_validation_phase validation: scripts/check-version-sync.sh not found or not executable"
        return 0
    fi
    if [ ! -f "$_project_root/VERSION" ]; then
        warn "Skipping $_validation_phase validation: VERSION file not found"
        return 0
    fi
    if [ ! -f "$_project_root/docs/version-sync-manifest.yml" ]; then
        warn "Skipping $_validation_phase validation: docs/version-sync-manifest.yml not found"
        return 0
    fi

    _validation_output="$TMPDIR/validation_$(basename "$_project_root").txt"
    info "Running $_validation_phase validation..."
    if (cd "$_project_root" && ./scripts/check-version-sync.sh) >"$_validation_output" 2>&1; then
        if ! $JSON_OUTPUT; then
            cat "$_validation_output"
        fi
        info "$_validation_phase validation passed."
        return 0
    else
        warn "$_validation_phase validation FAILED."
        sed 's/^/  /' "$_validation_output" >&2
        return 1
    fi
}

# ============================================================================
# Git branch creation
# ============================================================================

create_git_branch() {
    _project_root="$1"
    if [ -n "$ONLY_SELECTORS" ]; then
        _branch_name="dockit-sync-$TEMPLATE_VERSION-selective"
    else
        _branch_name="dockit-sync-$TEMPLATE_VERSION"
    fi

    if (cd "$_project_root" && git rev-parse --verify "$_branch_name" >/dev/null 2>&1); then
        if [ -n "$ONLY_SELECTORS" ]; then
            _branch_name="dockit-sync-${TEMPLATE_VERSION}-selective-$(date +%Y%m%d%H%M%S)"
        else
            _branch_name="dockit-sync-${TEMPLATE_VERSION}-$(date +%Y%m%d%H%M%S)"
        fi
    fi

    info "Creating git branch: $_branch_name"
    (cd "$_project_root" && git checkout -b "$_branch_name")
}

# ============================================================================
# Project discovery
# ============================================================================

find_projects() {
    _src_root="$1"
    _projects_file="$2"
    : > "$_projects_file"

    for _d in "$_src_root"/*/; do
        if [ -f "$_d/.dockit-enabled" ] && [ -d "$_d/.git" ]; then
            # Store realpath
            _rpath=$(cd "$_d" && pwd)
            echo "$_rpath" >> "$_projects_file"
        fi
    done
}

# ============================================================================
# Init state (bootstrap)
# ============================================================================

do_init_state() {
    _project_root="$1"
    _state_file="$_project_root/.git/$DOCKIT_DIR_NAME/state.yml"

    info "Initializing sync state for: $_project_root"

    # Compute section hashes for current state (if markers exist)
    _hashes_file="$TMPDIR/init_section_hashes.txt"
    : > "$_hashes_file"

    _entries_file="$TMPDIR/init_entries.txt"
    parse_manifest "$MANIFEST" "$_entries_file"

    while read -r _relpath _strategy; do
        if [ "$_strategy" = "section-merge" ]; then
            _downstream_file="$_project_root/$_relpath"
            _template_file="$DOCKIT_ROOT/$_relpath"

            if [ ! -f "$_downstream_file" ] || [ ! -f "$_template_file" ]; then
                continue
            fi

            # Get section IDs from template
            _init_sids="$TMPDIR/init_sids.txt"
            grep '<!-- DOCKIT-TEMPLATE:START ' "$_template_file" 2>/dev/null | \
                sed 's/.*<!-- DOCKIT-TEMPLATE:START //' | sed 's/ -->.*//' > "$_init_sids" || true

            while IFS= read -r _sid; do
                _start_marker="<!-- DOCKIT-TEMPLATE:START $_sid -->"
                _end_marker="<!-- DOCKIT-TEMPLATE:END $_sid -->"

                # Check if downstream has these markers
                if grep -q "^$_start_marker$" "$_downstream_file" 2>/dev/null && \
                   grep -q "^$_end_marker$" "$_downstream_file" 2>/dev/null; then
                    _content="$TMPDIR/init_content_${_sid}.txt"
                    awk -v start="$_start_marker" -v end="$_end_marker" '
                        $0 == start { capture=1; next }
                        $0 == end   { capture=0; next }
                        capture { print }
                    ' "$_downstream_file" > "$_content"
                    _hash=$(hash_file "$_content")
                    echo "$_relpath $_sid $_hash" >> "$_hashes_file"
                fi
            done < "$_init_sids"
        fi
    done < "$_entries_file"

    # Write state (no files modified)
    write_state "$_project_root" "init-state" "$_hashes_file"
    info "State initialized. No project files were modified."
    info "State written to: $_state_file"
}

# ============================================================================
# Main sync logic for one project
# ============================================================================

# sync_project returns 0 on success, 1 on failure.
# It never calls die() -- errors are reported and accumulated.
sync_project() {
    _project_root="$1"
    _project_name=$(basename "$_project_root")
    CURRENT_PROJECT="$_project_name"
    _state_file="$_project_root/.git/$DOCKIT_DIR_NAME/state.yml"
    _project_failed=false

    COUNT_UPDATED=0
    COUNT_NEW=0
    COUNT_SKIPPED=0
    COUNT_CONFLICT=0
    COUNT_ERROR=0
    HAS_CONFLICTS=false

    info ""
    info "=== Syncing: $_project_name ($MODE) ==="

    if [ ! -d "$_project_root/.git" ]; then
        report_entry "__project__" "ERROR" "not a git repository"
        return 1
    fi

    # Acquire lock
    if ! acquire_lock "$_project_root"; then
        report_entry "__project__" "ERROR" \
            "${LOCK_ERROR_DETAIL:-lock acquisition failed}"
        return 1
    fi

    # Handle --restore (before state check)
    if [ "$MODE" = "restore" ]; then
        if ! restore_backup "$_project_root" "$RESTORE_TS"; then
            report_entry "__project__" "ERROR" "backup not found: $RESTORE_TS"
            release_lock
            return 1
        fi
        release_lock
        return
    fi

    # Handle --init-state
    if [ "$MODE" = "init-state" ]; then
        do_init_state "$_project_root"
        release_lock
        return
    fi

    # Require state (unless init-state)
    if [ ! -f "$_state_file" ]; then
        report_entry "__project__" "ERROR" "no sync state; run --init-state first"
        release_lock
        return 1
    fi

    # Parse manifest entries
    _entries_file="$TMPDIR/entries.txt"
    parse_manifest "$MANIFEST" "$_entries_file"

    # Selective rollout should not be blamed for validation drift that already
    # existed. Classify and leave that adopter byte-identical.
    if [ -n "$ONLY_SELECTORS" ]; then
        if ! validate_project "$_project_root" "pre-sync"; then
            report_entry "__project__" "SKIPPED" "pre-existing validation failure"
            print_summary
            release_lock
            return 0
        fi
    fi

    # Create backup if applying
    if [ "$MODE" = "apply" ]; then
        create_backup_dir "$_project_root"
    fi

    # Create git branch if requested
    if $GIT_BRANCH && [ "$MODE" = "apply" ]; then
        if ! create_git_branch "$_project_root"; then
            report_entry "__project__" "ERROR" "failed to create sync branch"
            release_lock
            return 1
        fi
    fi

    # Initialize section hashes accumulator
    : > "$TMPDIR/all_section_hashes.txt"

    # Process each manifest entry
    while read -r _relpath _strategy; do
        if ! entry_is_selected "$_relpath"; then
            continue
        fi

        case "$_strategy" in
            skip)
                report_entry "$_relpath" "SKIPPED" "project-specific"
                ;;
            copy)
                sync_copy "$_project_root" "$_relpath"
                ;;
            section-merge)
                sync_section_merge "$_project_root" "$_relpath"
                ;;
            yaml-merge)
                sync_yaml_merge "$_project_root" "$_relpath"
                ;;
            *)
                report_entry "$_relpath" "ERROR" "unknown strategy: $_strategy"
                ;;
        esac
    done < "$_entries_file"

    # Check for unforced conflicts -> rollback
    if $HAS_CONFLICTS && ! $FORCE; then
        if [ "$MODE" = "apply" ] && [ -n "$BACKUP_DIR" ]; then
            warn "Conflicts detected without --force. Rolling back all changes."
            rollback "$_project_root" "$BACKUP_DIR"
            _project_failed=true
            report_entry "__project__" "ERROR" "rolled back: conflicts"
        else
            _project_failed=true
        fi
    fi

    # Rollback on errors in apply mode
    if [ "$COUNT_ERROR" -gt 0 ] && ! $_project_failed \
        && [ "$MODE" = "apply" ] && [ -n "$BACKUP_DIR" ]; then
        warn "Errors detected. Rolling back all changes."
        rollback "$_project_root" "$BACKUP_DIR"
        _project_failed=true
        report_entry "__project__" "ERROR" "rolled back: sync error"
    fi

    # Post-sync validation (only on apply, only if no errors/conflicts)
    if [ "$MODE" = "apply" ] && ! $_project_failed; then
        if ! validate_project "$_project_root" "post-sync"; then
            if [ -n "$BACKUP_DIR" ]; then
                warn "Validation failed. Rolling back all changes."
                rollback "$_project_root" "$BACKUP_DIR"
            fi
            _project_failed=true
            report_entry "__project__" "ERROR" "rolled back: post-sync validation failure"
        fi
    fi

    # Write state only on full success (no errors, no conflicts, no validation failure)
    if [ "$MODE" = "apply" ] && ! $_project_failed && [ -z "$ONLY_SELECTORS" ]; then
        _hashes_arg=""
        if [ -s "$TMPDIR/all_section_hashes.txt" ]; then
            _hashes_arg="$TMPDIR/all_section_hashes.txt"
        fi
        write_state "$_project_root" "apply" "$_hashes_arg"
    elif [ "$MODE" = "apply" ] && ! $_project_failed; then
        if [ -s "$TMPDIR/all_section_hashes.txt" ]; then
            _state_before="$TMPDIR/state_before_selective.yml"
            cp "$_state_file" "$_state_before"
            if ! write_state_selective "$_project_root" "$TMPDIR/all_section_hashes.txt"; then
                warn "Selective state merge failed. Rolling back all changes."
                cp "$_state_before" "$_state_file"
                if [ -n "$BACKUP_DIR" ]; then
                    rollback "$_project_root" "$BACKUP_DIR"
                fi
                _project_failed=true
                report_entry "__project__" "ERROR" "rolled back: selective state merge failure"
            fi
        fi
        if ! $_project_failed \
            && { [ "$COUNT_UPDATED" -gt 0 ] || [ "$COUNT_NEW" -gt 0 ]; }; then
            warn "Selective sync updated selected baselines but preserved template_version/template_ref; run a full sync before claiming the adopter is current."
        fi
    fi

    # Cleanup old backups
    if [ "$MODE" = "apply" ]; then
        cleanup_backups "$_project_root"
    fi

    # Print summary
    print_summary

    if [ "$MODE" = "apply" ] && ! $_project_failed \
        && { [ "$COUNT_UPDATED" -gt 0 ] || [ "$COUNT_NEW" -gt 0 ]; }; then
        warn "Sync applied successfully. Review and commit the resulting changes before opening unrelated sessions."
    fi

    # Release lock
    release_lock

    # Return failure if errors or unforced conflicts
    if $_project_failed || [ "$COUNT_ERROR" -gt 0 ]; then
        return 1
    fi
    return 0
}

# ============================================================================
# Argument parsing
# ============================================================================

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                MODE="dry-run"
                ;;
            --apply)
                MODE="apply"
                ;;
            --init-state)
                MODE="init-state"
                ;;
            --restore)
                MODE="restore"
                shift
                if [ -z "$1" ]; then
                    die "--restore requires a timestamp argument"
                fi
                RESTORE_TS="$1"
                ;;
            --project)
                shift
                if [ -z "$1" ]; then
                    die "--project requires a path argument"
                fi
                PROJECT_PATH="$1"
                ;;
            --all)
                SYNC_ALL=true
                ;;
            --src-root)
                shift
                if [ -z "$1" ]; then
                    die "--src-root requires a path argument"
                fi
                SRC_ROOT="$1"
                ;;
            --only)
                shift
                if [ -z "$1" ]; then
                    die "--only requires a selector argument"
                fi
                append_only_selector "$1"
                ;;
            --force)
                FORCE=true
                ;;
            --git-branch)
                GIT_BRANCH=true
                ;;
            --json)
                JSON_OUTPUT=true
                ;;
            -h|--help)
                awk 'NR == 1 { next } /^# This script runs/ { exit } /^#/ { sub(/^# ?/, ""); print }' "$0"
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
        shift
    done

    # Validate: must specify --project or --all
    if [ -z "$PROJECT_PATH" ] && ! $SYNC_ALL; then
        die "Must specify --project PATH or --all"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Determine DOCKIT_ROOT
    DOCKIT_ROOT=$(cd "$(dirname "$0")/.." && pwd)

    # Validate we're in LLM-DocKit
    if [ ! -f "$DOCKIT_ROOT/VERSION" ]; then
        die "VERSION file not found. Are you running from LLM-DocKit root?"
    fi

    MANIFEST="$DOCKIT_ROOT/dockit-sync-manifest.yml"
    if [ ! -f "$MANIFEST" ]; then
        die "dockit-sync-manifest.yml not found at $DOCKIT_ROOT"
    fi

    # Create temp dir with cleanup trap
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"; release_lock' EXIT INT TERM

    # Lint manifest (validates schema_version, tabs, entries, duplicates)
    lint_manifest "$MANIFEST"

    # Read template version and git ref
    TEMPLATE_VERSION=$(head -1 "$DOCKIT_ROOT/VERSION" | tr -d '[:space:]')
    TEMPLATE_REF=$(cd "$DOCKIT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    # Detect hash command
    detect_hash_cmd

    # Parse arguments
    parse_args "$@"
    validate_only_selectors

    info "LLM-DocKit Sync v$SYNC_TOOL_VERSION"
    info "Template: v$TEMPLATE_VERSION ($TEMPLATE_REF)"
    info "Mode: $MODE"
    if [ -n "$ONLY_SELECTORS" ]; then
        info "Scope: selective"
        while IFS= read -r _selector; do
            info "  - $_selector"
        done <<EOF
$ONLY_SELECTORS
EOF
    fi
    info ""

    # Build project list
    if [ -n "$PROJECT_PATH" ]; then
        # Single project
        _abs_path=$(cd "$PROJECT_PATH" 2>/dev/null && pwd) || die "Project path not found: $PROJECT_PATH"
        if [ ! -f "$_abs_path/.dockit-enabled" ]; then
            die "Project does not have .dockit-enabled: $_abs_path"
        fi
        if ! sync_project "$_abs_path"; then
            GLOBAL_EXIT=1
        fi
    else
        # All projects (best-effort: continue on failure, report at end)
        _projects_file="$TMPDIR/projects.txt"
        find_projects "$SRC_ROOT" "$_projects_file"

        if [ ! -s "$_projects_file" ]; then
            die "No .dockit-enabled projects found in $SRC_ROOT"
        fi

        _project_count=$(wc -l < "$_projects_file" | tr -d '[:space:]')
        info "Found $_project_count project(s) with .dockit-enabled"

        _failed_projects=""
        while IFS= read -r _proj; do
            if ! sync_project "$_proj"; then
                GLOBAL_EXIT=1
                _failed_projects="$_failed_projects $(basename "$_proj")"
            fi
        done < "$_projects_file"

        if [ -n "$_failed_projects" ]; then
            echo "" >&2
            echo "FAILED projects:$_failed_projects" >&2
        fi
    fi

    if $JSON_OUTPUT; then
        print_json_report
    fi

    exit "$GLOBAL_EXIT"
}

main "$@"
