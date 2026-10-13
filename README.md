<!-- doc-version: 4.20.0 -->
# <PROJECT_NAME>

<One-line description of what this project does.>

**Version:** see [VERSION](VERSION) | [CHANGELOG](CHANGELOG.md)

## Overview

<2-3 paragraphs describing the project, the problem it solves, and who it is for.>

## Quick Start

### Prerequisites
- <Prerequisite 1>
- <Prerequisite 2>

### Installation
```
<installation commands>
```

### Usage
```
<basic usage example>
```

## Documentation

| Document | Purpose |
|----------|---------|
| [LLM_START_HERE.md](LLM_START_HERE.md) | Entry point for LLM contributors |
| [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) | Vision, architecture, current state |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical architecture details |
| [docs/STRUCTURE.md](docs/STRUCTURE.md) | Repository layout |
| [docs/VERSIONING_RULES.md](docs/VERSIONING_RULES.md) | Version management policy |
| [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) | Current work state |
| [HOW_TO_USE.md](HOW_TO_USE.md) | Scaffold setup guide and sync tool docs |
| [docs/FLEET_ROLLOUT_2026-09-12.md](docs/FLEET_ROLLOUT_2026-09-12.md) | Verified independent-review policy fleet rollout ledger |

## Contributing

<Contributing guidelines or link to CONTRIBUTING.md.>

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.

---

*Documentation scaffold powered by [LLM-DocKit](https://github.com/cdelalama/LLM-DocKit).*

## Optional host intake policy

Before creating a project, the initializer executes the host-owned
`${XDG_CONFIG_HOME:-$HOME/.config}/llm-dockit/init-policy` when present, passing
`--project-name` and `--target-dir` as separate arguments. A nonzero result or
a broken/non-executable configured hook prevents all target writes. An absent
hook preserves generic behavior. The host owns its policy and installation;
DocKit does not select an ecosystem, registry, provider or monitoring product.
This is an accidental-omission guard, not a security boundary against edits to
host configuration. Adoption/sync do not rerun initialization or delete files.
SessionStart also calls the same fixed hook with `--check-existing --target-dir`
and reports its result in onboarding. That diagnosis requests corrective
adoption before new runtime work; it does not stop existing services or claim
consumer acceptance. Hosts implementing this optional hook support both modes.
