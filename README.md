# devdash-cli

Dev-Dash CLI — AI-powered task tracking for coding agents.

A lightweight bash CLI that wraps the [Dev-Dash](https://github.com/jasonmassey/dev-dash) REST API for managing tasks, dependencies, and agent jobs from the terminal.

## Install

### npm (recommended)

```bash
npm install -g devdash-cli
```

### curl

```bash
curl -fsSL https://raw.githubusercontent.com/jasonmassey/devdash-cli/main/install.sh | bash
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

## Usage

```bash
devdash ready                              # Show tasks ready to work
devdash create --title="Fix login bug"     # Create a task
devdash update <id> --status=in_progress   # Claim work
devdash close <id>                         # Mark complete
devdash stats                              # Project overview
```

### All commands

| Command | Description |
|---------|-------------|
| `login` | Authenticate via browser |
| `init` | Link current repo to a project |
| `list [--status=X]` | List tasks (optional filter) |
| `ready` | Tasks with no blockers |
| `blocked` | Tasks waiting on dependencies |
| `show <id>` | Task details |
| `create --title="..."` | Create task (`--type`, `--priority`, `--description`, `--parent`) |
| `update <id> --key=val` | Update fields (`--status`, `--priority`, `--owner`, `--title`, `--description`) |
| `close <id> [...]` | Close one or more tasks |
| `dep add <id> <dep-id>` | Add dependency |
| `jobs [list\|show\|log\|failures]` | Manage agent jobs |
| `reconcile-tasks` | AI-powered backlog audit |
| `stats` | Project statistics |
| `sync` | Sync with GitHub Issues |
| `prime` | Output workflow context for AI agents |
| `doctor` | Check prerequisites |
| `alias-setup` | Add `dd` shortcut alias |
| `self-update` | Update to latest version |

### dd alias

During install, you'll be prompted to alias `dd` to `devdash` for shorter commands. This shadows `/usr/bin/dd` (Unix disk copy) — only enable if you don't use that tool.

You can set it up any time:

```bash
devdash alias-setup
```

### Agent integration

The `prime` command outputs structured context for AI coding agents (e.g., Claude Code):

```bash
devdash prime
```

Use it as a session hook to inject workflow context automatically.

## Prerequisites

- `curl`, `jq`, `openssl`, `python3`, `git`
- A Dev-Dash account and project

## License

MIT
