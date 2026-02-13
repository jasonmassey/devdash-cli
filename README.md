# devdash-cli

Dev-Dash CLI — AI-powered task tracking for coding agents.

A lightweight bash CLI that wraps the [Dev-Dash](https://github.com/jasonmassey/dev-dash) REST API for managing tasks, dependencies, and agent jobs from the terminal.

## Install

### From GitHub (recommended)

```bash
npm install -g github:jasonmassey/devdash-cli
```

### curl

```bash
curl -fsSL https://raw.githubusercontent.com/jasonmassey/devdash-cli/main/install.sh | bash
```

### npm (coming soon)

```bash
npm install -g @devdashproject/devdash-cli
```

## Setup

```bash
# 1. Authenticate (opens browser for Google OAuth)
devdash login

# 2. Link to a project (auto-detects from git remote)
devdash init

# 3. Verify
devdash doctor
```

## Quick Start

```bash
devdash ready                              # Show tasks ready to work
devdash show <id>                          # View task details
devdash update <id> --status=in_progress   # Claim work
# ... do the work ...
devdash close <id>                         # Mark complete
```

### Creating tasks

```bash
devdash create --title="Fix login bug" --type=bug --priority=1
devdash create --title="Add dark mode" --type=feature --description="Support system theme"
```

### Managing dependencies

```bash
devdash create --title="Write tests" --type=task
devdash dep add <test-id> <feature-id>   # Tests depend on feature
devdash blocked                           # See what's waiting
```

## All Commands

| Command | Description |
|---------|-------------|
| `login` | Authenticate via browser (tries ports 18787-18792) |
| `init` | Link current repo to a project (auto-detects GitHub remote) |
| `project create` | Create a new project (`--name`, `--repo`, `--description`) |
| `project list` | List all your projects |
| `project delete <id>` | Delete a project (`--force` to skip confirmation) |
| `list [--status=X]` | List tasks (optional status filter) |
| `ready` | Tasks with no blockers, sorted by priority |
| `blocked` | Tasks waiting on dependencies |
| `show <id>` | Task details with dependencies |
| `create --title="..."` | Create task (`--type`, `--priority`, `--description`, `--parent`) |
| `update <id> --key=val` | Update fields (`--status`, `--priority`, `--owner`, `--title`, `--description`, `--pre-instructions`) |
| `close <id> [...]` | Close one or more tasks |
| `delete <id> [--force]` | Delete a task (with confirmation prompt) |
| `dep add <id> <dep-id>` | Add dependency (id depends on dep-id) |
| `jobs [list\|show\|log\|failures]` | Manage agent jobs |
| `reconcile-tasks` | AI-powered backlog audit (`--dry-run`, `--auto-fix`, `--json`) |
| `stats` | Project statistics |
| `sync` | Trigger full reconcile with GitHub |
| `prime` | Output workflow context for AI agents (includes project health) |
| `doctor` | Check prerequisites and configuration |
| `alias-setup` | Add `dd` shortcut alias |
| `self-update` | Update to latest version |

### Bead IDs

Commands accept UUIDs, short prefixes (e.g., `27bf`), or local IDs (`dev-dash-*`). Ambiguous prefixes are rejected with suggestions.

### dd alias

During install, you'll be prompted to alias `dd` to `devdash` for shorter commands. This shadows `/usr/bin/dd` (Unix disk copy) — only enable if you don't use that tool.

```bash
devdash alias-setup
```

### Agent integration

The `prime` command outputs structured context for AI coding agents (e.g., Claude Code):

```bash
devdash prime
```

It includes project name, health stats, command reference, and workflow patterns. Use it as a session hook to inject workflow context automatically.

### Multi-project setup

Each repo gets its own `.devdash` file linking it to a project. The CLI reads this file to determine which project to use:

```bash
cd my-project && devdash init    # Links this repo
cd other-repo && devdash init    # Links that repo separately
```

You can also set `DD_PROJECT_ID` and `DD_API_URL` environment variables to override.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Not logged in` | Run `devdash login` |
| `No project configured` | Run `devdash init` in your repo |
| `Port 18787 in use` during login | CLI auto-tries ports 18787-18792 |
| `API error (401)` | Token expired — re-run `devdash login` |
| `jq: command not found` | Install jq: `brew install jq` or `apt install jq` |
| Commands seem slow | API latency — ensure good network connection |

Run `devdash doctor` to check all prerequisites and configuration.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User error (bad arguments, unknown command) |
| 2 | API error (network, auth, server error) |
| 3 | Config error (not logged in, no project) |

## Prerequisites

- `curl`, `jq`, `openssl`, `python3`, `git`
- A Dev-Dash account and project

## License

MIT
