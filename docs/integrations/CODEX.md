<!-- doc-version: 4.12.0 -->
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
- creates a timestamped backup before changing the file;
- replaces the older unmarked LLM-DocKit block that used `--json`.

For tests or non-standard installations:

```sh
scripts/dockit-install-codex-hook.sh \
  --config /tmp/codex-config.toml \
  --script ~/src/LLM-DocKit/scripts/dockit-bootstrap-context.sh
```

## Verify

Open a fresh Codex CLI session in a repo that has `LLM_START_HERE.md`. The
first substantive answer should begin with:

```text
Onboarding loaded.
```

It should not repeat that marker on every later answer. If it still repeats
after the `--human` hook is installed, the likely cause is Codex CLI hook
lifecycle behavior rather than the old JSON-envelope mismatch. File that as the
DF-037 follow-up before adding a stateful `--codex` mode.

## Ownership

LLM-DocKit owns the hook payload and the Codex installer. ForgeOS may call this
installer from operator bootstrap, but ForgeOS owns the broader operator runtime
and LMConsole surface. Home Infra should not maintain an independent Codex hook;
it can document that the operator machine is provisioned through the
LLM-DocKit/ForgeOS bootstrap chain.
