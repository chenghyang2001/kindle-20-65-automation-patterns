# CLAUDE.md (@ import syntax example)

<!--
File structure (targets of @ references):

import-example/
├── CLAUDE.md                  ← this file
├── README.md                  ← referenced by @README.md
├── package.json               ← referenced by @package.json
└── docs/
    ├── git-workflow.md        ← referenced by @docs/git-workflow.md
    ├── api-conventions.md     ← referenced by @docs/api-conventions.md
    └── testing-guidelines.md  ← referenced by @docs/testing-guidelines.md
-->

See @README.md for the project overview.
Available commands are listed in @package.json.

# Additional Instructions

- Git workflow: @docs/git-workflow.md
- API design conventions: @docs/api-conventions.md
- Testing guidelines: @docs/testing-guidelines.md

# Personal Settings

Add personal settings to CLAUDE.local.md.
CLAUDE.local.md is automatically added to .gitignore.
