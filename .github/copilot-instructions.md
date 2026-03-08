# DevDash — AI Agent Task Tracking

<!-- devdash:agent-instructions -->

This project uses **devdash** for task tracking. Use the `devdash` CLI for ALL task
management. Do NOT use TodoWrite, TaskCreate, `bd`, or markdown files for tracking tasks.

## Rules (MANDATORY)

1. **Issue-first**: Create a devdash issue BEFORE writing code. No exceptions.
2. **Issue-per-commit**: Every git commit must correspond to a devdash issue. If you do
   follow-up work or scope expands, create new issues for the additional commits.
3. **Mark in-progress**: Run `devdash update <id> --status=in_progress` before starting work.
4. **Pre-commit checkpoint**: Before each `git commit`, verify you have a devdash issue
   for this work. If not, create one immediately.
5. **Close after push**: Only close issues after `git push` succeeds — never before.
6. **No orphaned work**: At session end, every commit you made must map to a closed
   devdash issue. Audit with `devdash list --status=in_progress` and close or create as needed.

## Install

```bash
npm install -g github:jasonmassey/devdash-cli
```

## Session Start

Run `devdash prime` at the start of every session to get live project context
(health stats, project ID, available commands).

## Essential Commands

| Command | Description |
|---------|-------------|
| `devdash ready` | Show issues ready to work (unblocked) |
| `devdash list` | All open issues |
| `devdash list --status=in_progress` | Your active work |
| `devdash show <id>` | Issue details with dependencies |
| `devdash blocked` | Show blocked issues |
| `devdash create --title="..." --type=task\|bug\|feature --priority=2` | Create issue |
| `devdash update <id> --status=in_progress` | Claim work |
| `devdash close <id> [--pr=URL] [--commit=SHA] [--summary="..."]` | Mark complete (with optional metadata) |
| `devdash close <id1> <id2> ...` | Close multiple issues |
| `devdash dep add <issue> <depends-on>` | Add dependency |
| `devdash stats` | Project statistics |

### Priority Scale

0 = critical, 1 = high, 2 = medium (default), 3 = low, 4 = backlog

### ID Formats

Bead IDs can be full UUIDs, UUID prefixes (e.g. `27bf`), or local IDs (`dev-dash-*`).

## Workflow

### Starting work
```bash
devdash ready                              # Find available work
devdash show <id>                          # Review details
devdash update <id> --status=in_progress   # Claim it
```

### Completing work (Session Close Protocol)
```
1. git status           (check what changed)
2. git add <files>      (stage code changes)
3. git commit -m "..."  (commit code)
4. git push             (push to remote)
5. devdash close <id>   (mark task complete)
```

**NEVER skip the git push.** Work is not done until pushed.

### Creating dependent work
```bash
devdash create --title="Implement feature X" --type=feature
devdash create --title="Write tests for X" --type=task
devdash dep add <tests-id> <feature-id>   # Tests depend on feature
```
<!-- /devdash:agent-instructions -->
