# Repository Structure Guide

Use this template to document how the repository is organized. Update the table below once your folders and files are in place.

## Top-Level Layout
`
<PROJECT_ROOT>/
+- README.md
+- LLM_START_HERE.md
+- docs/
+- src/ (optional)
+- scripts/ (optional)
+- tests/ (optional)
+- .github/ (optional)
+- ...
`

## Directory Descriptions
| Path | Purpose | Notes |
|------|---------|-------|
| docs/ | Central documentation, policies, and runbooks | Required |
| docs/llm/ | Handoff and history for LLM contributors | Required |
| docs/operations/ | Runbooks and operational procedures | Recommended |
| src/ | Application or library source code | Optional |
| scripts/ | Utility scripts or tooling | Optional |
| tests/ | Automated tests | Optional |
| .github/ | Issue/PR templates and workflows | Optional |

## Generated / Runtime Directories (Optional)
Document directories that are produced at runtime/build time and should not be committed.

Examples:
- `output/` - generated artifacts
- `audio/` - downloaded or derived media
- `dist/` - build outputs
- `node_modules/` - dependencies (Node.js)
- `.venv/` - virtual environment (Python)

## Custom Modules or Packages
Document any additional folders specific to your project. Explain how they relate to the architecture in docs/PROJECT_CONTEXT.md.

## Naming Conventions
Outline conventions for file names, branches, environment variables, or other project-wide patterns.

## Onboarding Notes
Provide tips for new contributors (human or LLM) on where to start, which directories to explore first, and any caveats about legacy code or experimental features.
