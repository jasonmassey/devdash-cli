# Getting Started with Dev-Dash

Welcome! This guide will get you from zero to managing tasks in about 5 minutes.

## What is Dev-Dash?

Dev-Dash is a task tracker built for developers who work with AI coding agents. It has two parts:

- **Web dashboard** at [devdash.dev](https://devdash.dev) — create projects, manage your team, connect GitHub, dispatch AI agents
- **CLI** (`devdash`) — manage tasks without leaving your terminal

They stay in sync automatically. Use whichever feels right for the moment.

---

## Step 1: Install the CLI

You'll need Node.js 18+ and a few common tools (`curl`, `jq`, `git`).

```bash
npm install -g github:jasonmassey/devdash-cli
```

Verify it worked:

```bash
devdash version
# => devdash 0.2.0
```

If anything looks off, run the built-in checkup:

```bash
devdash doctor
```

It'll tell you exactly what's missing.

---

## Step 2: Log in

```bash
devdash login
```

Your browser will open for Google sign-in. After you authenticate, the token is saved locally and you're done — no passwords to remember, no keys to paste.

> **First time?** If you don't have a Dev-Dash account yet, one is created automatically when you sign in with Google. No separate signup required.

---

## Step 3: Create or connect a project

### Option A: Start from the web (recommended for new projects)

1. Head to [devdash.dev](https://devdash.dev) and sign in
2. You'll land on the **onboarding page** — click **Connect GitHub**
3. Pick a repo from the list (or enter a project name manually)
4. Hit **Create Project**

Dev-Dash will scan your GitHub issues and pull them in as tasks automatically. You can see them immediately in the **Tasks** tab.

Then in your terminal, inside the repo:

```bash
devdash init
```

It auto-detects your GitHub remote and links the CLI to your project. A small `.devdash` file is created — commit it so teammates can use the CLI too.

### Option B: Start from the CLI

If you'd rather skip the browser:

```bash
devdash project create --name="My Project" --repo=owner/repo
devdash init
```

You can always connect GitHub and configure team settings from the web dashboard later.

---

## Step 4: Set up the shortcut (optional)

During `init`, you'll be asked if you want to alias `dd` to `devdash`. If you said no (or missed it), you can do it anytime:

```bash
devdash alias-setup
```

From here on, the examples use `dd`. If you skipped the alias, substitute `devdash` everywhere.

> **Heads up:** This shadows `/usr/bin/dd` (a Unix disk-copy utility). If you use that tool regularly, skip the alias and use the full name `devdash`.

---

## Step 5: Configure your AI agents (optional)

If you use AI coding agents (Claude Code, Codex, Cursor, Copilot, Windsurf, Cline), you can auto-generate config files so they know to use `dd` for task tracking:

```bash
dd agent-setup
```

This auto-detects which agents you use and writes the appropriate config files. You can also specify agents directly:

```bash
dd agent-setup --agent=claude,codex    # Just these two
dd agent-setup --all                   # All supported agents
dd agent-setup --all --force           # Overwrite existing configs
```

Each agent gets instructions telling it to use `dd` commands, run `dd prime` at session start, and follow the git-push-before-close workflow.

The canonical instructions are also saved to `.devdash-agents/agent-instructions.md` for reference.

---

## Step 6: Explore your project

See what's ready to work on:

```bash
dd ready
```

This shows all unblocked tasks sorted by priority. Pick one and dig in:

```bash
dd show <id>
```

You can use the full UUID, a short prefix (like `27bf`), or a local ID (like `dev-dash-42`). The CLI figures it out.

---

## Your first workflow

Here's the day-to-day loop:

```bash
# What needs doing?
dd ready

# Claim a task
dd update <id> --status=in_progress

# ... write code, fix bugs, ship features ...

# Done!
dd close <id>
```

### Create a task

```bash
dd create --title="Fix login redirect" --type=bug --priority=1
```

Priority runs from 0 (critical) to 4 (backlog). Type can be `task`, `bug`, or `feature`.

### Add a dependency

Some things need to happen in order:

```bash
dd create --title="Write API endpoint" --type=task
dd create --title="Write tests for endpoint" --type=task
dd dep add <tests-id> <endpoint-id>
```

Now the tests task won't show up in `dd ready` until the endpoint task is closed.

### Check the big picture

```bash
dd stats
```

```
Total:       42
Pending:     28
In Progress: 3
Completed:   11
Blocked:     7
Ready:       21
```

---

## The web dashboard

The CLI handles task management, but the dashboard gives you a few extras:

| Feature | Where to find it |
|---------|-----------------|
| **Kanban board** | Project > Board tab |
| **AI agent dispatch** | Project > Agents tab |
| **GitHub sync settings** | Project > Settings tab |
| **Team invitations** | Project > Settings > Members |
| **API keys** (Anthropic, OpenAI) | Settings page (top-right menu) |
| **GitHub connection** | Settings > GitHub |

To invite a teammate, go to your project settings and add their email. When they sign in with Google, they'll automatically get access.

---

## Working with AI agents

Dev-Dash is designed to work alongside AI coding agents like Claude Code.

### Inject context into your agent session

```bash
dd prime
```

This outputs a structured block of context — your project name, health stats, available commands, and workflow patterns. Set it up as a session hook so your agent always knows how to use `dd`.

### Dispatch agents from the dashboard

In the **Agents** tab, you can assign a task to an AI agent and watch it work. The agent gets your repo, the task description, and project context, then runs in a sandboxed environment.

Check on agent jobs from the CLI:

```bash
dd jobs              # Recent runs
dd jobs show <id>    # Details + failure analysis
dd jobs failures     # What went wrong
```

---

## Multi-repo setup

Each repo gets its own `.devdash` file. Just run `init` in each one:

```bash
cd ~/projects/frontend && dd init
cd ~/projects/backend && dd init
cd ~/projects/infra && dd init
```

The CLI reads `.devdash` to know which project you're working in. No global state to juggle.

---

## Quick reference

| Command | What it does |
|---------|-------------|
| `dd login` | Sign in via browser |
| `dd init` | Link repo to project |
| `dd ready` | Show unblocked tasks |
| `dd list` | All open tasks |
| `dd show <id>` | Task details |
| `dd create --title="..."` | New task |
| `dd update <id> --status=in_progress` | Claim work |
| `dd close <id>` | Mark done |
| `dd dep add <a> <b>` | A depends on B |
| `dd blocked` | Show stuck tasks |
| `dd stats` | Project health |
| `dd prime` | AI agent context |
| `dd agent-setup` | Configure AI agents |
| `dd doctor` | Check setup |

---

## Troubleshooting

**"Not logged in"** — Run `dd login`.

**"No project configured"** — Run `dd init` inside your repo.

**Login port in use** — The CLI auto-tries ports 18787-18792. If all are busy, free one up and retry.

**"jq: command not found"** — Install it: `brew install jq` (macOS) or `apt install jq` (Linux).

**Tasks not syncing with GitHub** — Check your GitHub connection in the web dashboard under Settings. You may need to re-authorize.

When in doubt: `dd doctor` checks everything.

---

That's it! You're set up and ready to ship. Happy building.
