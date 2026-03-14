# Understanding the Dev-Dash Workflow

You've installed Dev-Dash, created a project, and linked your repo. Now what?

This guide covers the core concepts and the two main ways to get work done: **using a coding agent** or **working manually** through the dashboard and CLI. Both paths follow the same loop.

---

## Core Concepts

### Tasks

A task (also called a "bead") is the fundamental unit of work. Every bug fix, feature, spike, or improvement is a task. Tasks have a **type** (bug, feature, task, enhancement), a **priority** (0–4), and a **status** (pending, in progress, completed).

You don't need to overthink task structure. Create one when you know something needs doing. If a task turns out to be bigger than expected, Dev-Dash can break it down for you (see [Analysis](#analysis) below).

### Analysis

Analysis is what makes Dev-Dash more than a task list. When you analyze a task, Dev-Dash reads your repository and produces:

- A **complexity estimate** — is this a quick fix or a multi-file refactor?
- A list of **affected files and modules** — what parts of the codebase are involved?
- **Agent instructions** — a step-by-step implementation plan an AI agent can follow
- **Subtask recommendations** — if the work is too large for one pass, a breakdown into smaller pieces with their own instructions

Analysis bridges the gap between "fix the login bug" and an agent (or developer) knowing exactly what to do. It's optional but powerful — especially for non-trivial work.

### Dispatch

Dispatch is running an AI coding agent on a task. The agent gets your repository, the task description, and any analysis/instructions, then works in a sandboxed environment. You can watch the output live and review the results when it finishes.

### The Loop

Regardless of whether you use agents or do the work yourself, the workflow is:

```
Create or pick a task  →  Understand it  →  Do the work  →  Ship it  →  Close it
```

The middle steps change depending on your approach. The rest of this guide walks through each.

---

## Workflow A: AI Agent (Analyze → Dispatch)

This is the primary workflow Dev-Dash is built for. You describe what needs doing, and an AI agent does the implementation.

### 1. Start with a task

**In the dashboard:** Open your project. The **Board** tab shows tasks in a kanban layout sorted by readiness — a score based on priority, age, and whether blockers are resolved. Pick something from the "Ready" column.

**From the CLI:** Run `dd ready` to see unblocked tasks sorted by priority. Use `dd show <id>` to read the full description.

### 2. Analyze it

**In the dashboard:** Click **Analyze** on any task — available from the Board, the Tasks list, or the Dispatch tab. You'll see a progress indicator as Dev-Dash maps your repo structure, selects relevant source files, assesses complexity, and generates an implementation plan.

When it finishes, you get a modal showing the complexity estimate, affected files, and generated agent instructions. If the task is complex, it will suggest (or automatically create) subtasks, each with their own instructions.

**From the CLI:** Analysis is currently a dashboard feature. You can view analysis results for a task with `dd show <id>` after analysis has been run.

### 3. Dispatch an agent

**In the dashboard:** After reviewing the analysis, click **Dispatch Agent**. The agent runs in a sandbox with your repo and the generated instructions. Watch the live terminal output in the job viewer.

For tasks that were auto-decomposed into subtasks, you can dispatch agents for each subtask — they'll run independently.

**From the CLI:** Monitor running agents with `dd jobs`. Watch a specific job's output with `dd jobs log <id>`. If something fails, `dd diagnose <id>` pulls together the task status, job history, and failure details.

### 4. Review and ship

When the agent finishes, it either creates a pull request or pushes directly (depending on your project's merge strategy, configured in Settings). Review the changes like you would any PR.

Once you're satisfied, merge and close the task — from the dashboard or with `dd close <id>`.

---

## Workflow B: Manual (with a coding agent at your side)

If you prefer to drive the implementation yourself — with a local coding agent like Claude Code, Copilot, or Cursor — Dev-Dash keeps your work organized and gives your agent context.

### 1. Set up agent integration

Run `dd agent-setup` once per repo. This generates config files for your coding agents (Claude Code, Codex, Cursor, Copilot, Windsurf, Cline) that teach them to use Dev-Dash for task tracking.

With this in place, your coding agent will automatically:

- Check `dd ready` for available work
- Claim tasks before starting (`dd update <id> --status=in_progress`)
- Create new tasks when scope expands
- Close tasks after pushing code

### 2. Pick a task and start working

**In the dashboard:** Drag a task to "In Progress" on the Board tab.

**From the CLI (or tell your agent):** `dd ready` → pick a task → `dd update <id> --status=in_progress`.

If you're working with a coding agent, you can just say "check devdash for ready tasks" and it will handle the rest.

### 3. Write code and commit

Work as you normally would. Your coding agent (if configured) will use Dev-Dash to track what it's doing. When the work is done:

```bash
git add <files>
git commit -m "Fix the thing"
git push
```

### 4. Close the task

**In the dashboard:** Open the task and mark it complete, or drag it to "Completed" on the board.

**From the CLI:** `dd close <id>`

---

## Workflow C: Dashboard-only (no code, no CLI)

Some work doesn't involve writing code locally — triaging bugs, planning features, managing a backlog. The dashboard handles all of it.

### Triage and organize

The **Tasks** tab is your backlog. Create tasks, set priorities, and group related work under parent tasks. You can also use **AI chat mode** to describe work conversationally — Dev-Dash creates the tasks for you.

### Analyze your backlog

Run analysis on tasks you're considering. The complexity estimates and file impact analysis help you prioritize and estimate effort without reading the code yourself.

### Dispatch and monitor

Send tasks to agents directly from the dashboard. The **Jobs** page gives you a global view of all agent activity across projects — what's queued, what's running, what failed.

### Plan across projects

The **Orchestration** page lets you build plans that span multiple projects and track progress across the whole effort.

---

## Key Dashboard Features

These are available from the web at [dev-dash-blue.vercel.app](https://dev-dash-blue.vercel.app):

**Board tab** — Kanban view of tasks. Sort by priority, readiness, or recency. Filter by time range. Analyze and dispatch directly from cards.

**Tasks tab** — Full task list with hierarchical parent/child display. Filter by status, type, and priority. Bulk import from GitHub Issues. AI chat mode for conversational task creation.

**Dispatch tab** — Select a task or type a freeform prompt. Analyze before dispatching. View job output in a live terminal.

**Activity tab** — Timeline of everything that's happened in the project — task changes, agent runs, job completions.

**Agents tab** — Configure which AI models to use for different stages (thinking, analysis, execution). Override defaults per project.

**Settings tab** — Project name, GitHub connection, merge strategy, GitHub sync toggle, team members and permissions.

**Jobs page** — Global view of all agent jobs. Cancel, retry, or inspect failures. Watch live output.

**Orchestration page** — Multi-project plans and cross-project task tracking.

---

## Tips

**You don't need to manually organize everything.** Analysis can break down complex tasks into subtasks automatically. Let the tool do the decomposition — you focus on describing what needs to happen.

**GitHub Issues sync both ways.** If you connect GitHub in project settings, existing issues get pulled in as tasks, and task updates can flow back. You don't have to choose between GitHub Issues and Dev-Dash.

**Agent instructions carry context.** When you analyze a task, the generated instructions include specific file paths, module names, and implementation steps. Agents that receive these instructions know exactly where to look and what to change.

**The CLI and dashboard are interchangeable.** Create a task in the dashboard, close it from the CLI. Dispatch an agent from the web, check on it with `dd jobs`. Use whatever's convenient.

**`dd doctor` fixes most setup issues.** If something isn't working, start there.
