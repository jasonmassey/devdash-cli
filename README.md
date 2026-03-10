# devdash-cli

Dev-Dash CLI — AI-powered task tracking for coding agents.

A lightweight bash CLI that wraps the [Dev-Dash](https://dev-dash-blue.vercel.app/) REST API for managing tasks, dependencies, and agent jobs from the terminal.

This CLI can be run in your terminal but is optimized for agents. Don't feel like you need to memorize the commands; your agent should be familiar enough!

**New here?** Check out the **[Getting Started guide](GETTING-STARTED.md)** for a friendly walkthrough.

## Install

```bash
npm install -g github:jasonmassey/devdash-cli
```

Or without npm:

```bash
curl -fsSL https://raw.githubusercontent.com/jasonmassey/devdash-cli/main/install.sh | bash
```

## Setup

```bash
# 1. Authenticate (opens browser for Google OAuth)
devdash login

# 2. Link to a project
devdash init                    # Auto-detects from git remote
devdash init MyProject          # Match by name (case-insensitive)
devdash init 896b3dbc           # Match by ID prefix

# 3. Verify
devdash doctor
```

During init you'll be offered to set up the `dd` alias and configure AI agent instructions.

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
| `init [name-or-id]` | Link repo to a project (auto-detect, name, ID prefix, or interactive picker) |
| `project create` | Create a new project (`--name`, `--repo`, `--description`) |
| `project list` | List all your projects |
| `project delete <id>` | Delete a project (`--force` to skip confirmation) |
| `list [--status=X] [--since=X]` | List tasks (optional status and time filter) |
| `ready [--since=X]` | Tasks with no blockers, sorted by priority |
| `blocked` | Tasks waiting on dependencies |
| `stale [--since=X]` | In-progress tasks with no recent activity |
| `show <id>` | Task details with dependencies |
| `create --title="..."` | Create task (`--type`, `--priority`, `--description`, `--parent`) |
| `update <id> --key=val` | Update fields (`--status`, `--priority`, `--owner`, `--title`, `--description`, `--pre-instructions`) |
| `close <id> [...] [--pr=URL] [--commit=SHA] [--summary="..."]` | Close one or more tasks (with optional completion metadata) |
| `delete <id> [--force] [--cascade]` | Delete a task (`--cascade` deletes children) |
| `dep add <id> <dep-id>` | Add dependency (id depends on dep-id) |
| `report <id> --status=X` | Log agent progress (`code_complete\|committed\|pushed\|error`) |
| `diagnose <id>` | Investigate bead: status, job history, failure details |
| `jobs [--bead=<id>]` | List recent jobs (optionally filtered by bead) |
| `jobs show <id>` | Job details + failure analysis |
| `jobs log <id> [--tail=N]` | Job output log (last N lines if specified) |
| `jobs failures [--bead=<id>]` | Recent failed jobs (optionally filtered by bead) |
| `reconcile-tasks` | AI-powered backlog audit (`--dry-run`, `--auto-fix`, `--json`) |
| `stats` | Project statistics |
| `sync` | Trigger full reconcile with GitHub |
| `import <num> \| --all` | Import GitHub issue(s) into the project |
| `prime` | Output workflow context for AI agents (includes project health) |
| `doctor` | Check prerequisites and configuration |
| `agent-setup` | Configure AI agent instructions (`--agent=X`, `--all`, `--force`) |
| `alias-setup` | Add `dd` shortcut alias |
| `token create\|list\|revoke` | Manage API tokens |
| `self-update` | Update to latest version |

### Bead IDs

Commands accept UUIDs, short prefixes (e.g., `27bf`), or local IDs (`dev-dash-*`). Ambiguous prefixes are rejected with suggestions.

### dd alias

During `devdash init`, you'll be prompted to alias `dd` to `devdash` for shorter commands. This shadows `/usr/bin/dd` (Unix disk copy) — only enable if you don't use that tool.

```bash
devdash alias-setup
```

### Agent integration

`devdash init` detects AI agent configs (CLAUDE.md, .cursor/, AGENTS.md, etc.) and offers to run `agent-setup` automatically. You can also run it directly:

```bash
devdash agent-setup              # Interactive — detects your agents
devdash agent-setup --agent=claude,codex
devdash agent-setup --all --force
```

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
