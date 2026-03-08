# DevDash — AI Agent Task Tracking

<!-- devdash:agent-instructions -->

This project uses **devdash** (`dd`) for task tracking. Run devdash commands yourself
via the terminal — do not just tell the user to run them. Do NOT use TodoWrite,
TaskCreate, `bd`, or markdown files for tracking. When the user says "dd", they mean
the devdash CLI, not the Unix `dd` data-copy utility.

## Rules (MANDATORY)

- **Issue-first**: Create a devdash issue BEFORE writing code. No exceptions.
- **Issue-per-commit**: Every git commit must map to a devdash issue. If scope expands, create new issues.
- **Mark in-progress**: `devdash update <id> --status=in_progress` before starting work.
- **Pre-commit checkpoint**: Before each `git commit`, verify you have an issue. If not, create one.
- **Close after push**: Only close issues after `git push` succeeds — never before.
- **No orphaned work**: At session end, every commit must map to a closed issue.

## CLI Reference

### Viewing issues
- `devdash ready` — Pending + unblocked issues sorted by priority. Excludes thoughts. **Start here.**
- `devdash list [--status=pending|in_progress|completed]` — All issues, optionally filtered by status.
- `devdash blocked` — Pending issues with unsatisfied dependencies.
- `devdash show <id>` — Full issue detail: description, dependencies, pre-instructions, parent.
- `devdash stats` — Project health: open/closed/blocked counts.

### Creating & updating
- `devdash create --title="..." [--type=task|bug|feature|enhancement] [--priority=0-4] [--description="..."] [--parent=<id>]`
- `devdash update <id> [--status=pending|in_progress] [--title="..."] [--description="..."] [--priority=0-4] [--owner=name] [--parent=<id>] [--pre-instructions="..."]`
- `devdash close <id> [<id>...] [--pr=URL] [--commit=SHA] [--summary="..."]` — Mark one or many issues completed, optionally with completion metadata.
- `devdash delete <id> [--force] [--cascade]`

### Dependencies
- `devdash dep add <issue> <depends-on>` — Issue is blocked until depends-on completes.

### IDs
Full UUID, UUID prefix (e.g. `27bf`), or local ID (`dev-dash-42`).

### Priority
0=critical, 1=high, 2=medium (default), 3=low, 4=backlog. Integers only.

### Cross-project
`DD_PROJECT_ID=<full-uuid> devdash <command>`

## Workflow

### Starting work
`devdash ready` → `devdash show <id>` → `devdash update <id> --status=in_progress`

### Completing work
`git add` → `git commit` → `git push` → `devdash close <id>`
Git operations MUST succeed before closing. Never run git and devdash close in parallel.

### Creating pull requests
When opening a PR, include a `## DevDash` footer section linking the devdash issue(s):

```
## DevDash
Project: `95ca3de0-7e4f-4f9e-9b17-36f5609cfa11`
Issues:
- [<issue-id>](https://dev-dash-blue.vercel.app/issue/<issue-id>)
```

Replace `<issue-id>` with the full UUID of each devdash issue the PR addresses.
If the PR addresses multiple issues, list each on its own line.

### Creating dependent work
`devdash create --title="Feature X" --type=feature` → `devdash create --title="Tests for X" --type=task` → `devdash dep add <tests-id> <feature-id>`

## Agent-Specific Instructions

- You may use your built-in task tools (TaskCreate, TodoWrite, etc.) for your own tracking, but you **must also** create and update devdash issues. Devdash is the system of record.
- When the user asks you to implement a plan, feature, or fix: your **very first action** is `devdash create`. Do not read files, do not write code — create the issue first.
- For multi-step plans, create one devdash issue per logical unit of work before starting any implementation.
- After creating issues, follow the normal workflow: mark in-progress, do the work, commit, then close.
<!-- /devdash:agent-instructions -->
