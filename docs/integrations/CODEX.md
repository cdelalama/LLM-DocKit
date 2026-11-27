<!-- doc-version: 4.26.0 -->
# Codex CLI Integration

LLM-DocKit's session-start onboarding uses `scripts/dockit-bootstrap-context.sh`.
Claude Code and Codex CLI need different output modes:

| Tool | Hook mode | Why |
|------|-----------|-----|
| Claude Code | `--json` | Claude Code parses `hookSpecificOutput.additionalContext`. |
| Codex CLI | `--human` | Codex CLI receives plain text; it does not parse the Claude hook JSON envelope. |
| Cursor / web ChatGPT / tools without hooks | `--human` manually pasted | Same text, operator-delivered. |

Do not install Codex CLI with `--json`. That mode can surface raw JSON in the
prompt and can make the model repeat the onboarding marker on every turn.

## Install

Run the installer from the canonical LLM-DocKit checkout:

```sh
~/src/LLM-DocKit/scripts/dockit-install-codex-hook.sh
```

The installer:

- edits `~/.codex/config.toml`;
- enables `[features] hooks = true`;
- installs a managed `[[hooks.SessionStart]]` block that calls
  `dockit-bootstrap-context.sh --human`;
- uses a non-login `sh -c` command with a bounded 15-second timeout, so shell
  profile initialization is not part of SessionStart latency;
- preserves `[hooks.state]`, MCP servers, and other operator-owned TOML tables
  even if Codex placed them before the managed END marker;
- creates a timestamped backup before changing the file;
- replaces the older unmarked LLM-DocKit block that used `--json`.

For tests or non-standard installations:

```sh
scripts/dockit-install-codex-hook.sh \
  --config /tmp/codex-config.toml \
  --script ~/src/LLM-DocKit/scripts/dockit-bootstrap-context.sh
```

## Verify

Changing the command or timeout changes the hook definition hash. After
re-running the installer, open `/hooks`, review the changed SessionStart hook,
and trust its new hash before expecting it to run. Codex skips changed
non-managed hooks until they are trusted.

Open a fresh Codex CLI session in a repo that has `LLM_START_HERE.md`. The
first substantive answer should begin with:

```text
Onboarding loaded.
```

It should not repeat that marker on every later answer. If it still repeats
after the `--human` hook is installed, the likely cause is Codex CLI hook
lifecycle behavior rather than the old JSON-envelope mismatch. File that as the
DF-037 follow-up before adding a stateful `--codex` mode.

The release process does not reinstall the operator hook automatically. Treat
installation as a separate operator action: inspect the backup and resulting
config diff, complete `/hooks` review, then start a fresh verification session.

## Update notices (central-only)

`scripts/dockit-update-notice.py` gives running sessions one notice when the
central DocKit VERSION changes. Install it for Claude Code and each Codex home:

```sh
~/src/LLM-DocKit/scripts/dockit-update-notice.py install \
  --claude-settings ~/.claude/settings.json \
  --codex-config ~/.codex/config.toml \
  --codex-config ~/.codex-lamanoriega/config.toml
```

It adds a SessionStart hook (records the session baseline) and a
UserPromptSubmit hook (silent unless VERSION changed). Codex runs both only
after they are trusted in `/hooks`, once per Codex home. `uninstall` with the
same flags removes only the managed entries. A resumed or compacted session
keeps its baseline. Sessions that began before installation get one notice
worded "may be older" on their next prompt during the first 7 days after
install; later, a missing baseline is recorded silently. The notice never syncs
project files; it names the operator-gated dry run when a project lags.

## Ownership

LLM-DocKit owns the hook payload and the Codex installer. ForgeOS may call this
installer from operator bootstrap, but ForgeOS owns the broader operator runtime
and LMConsole surface. Home Infra should not maintain an independent Codex hook;
it can document that the operator machine is provisioned through the
LLM-DocKit/ForgeOS bootstrap chain.
