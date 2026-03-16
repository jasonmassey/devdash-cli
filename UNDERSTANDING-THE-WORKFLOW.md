# Understanding the Dev-Dash Workflow

## Why Dev-Dash?

Most coding agents build a task list internally when working through a complex problem, but this thinking chain is not exposed outside of the agent itself. For a problem with multiple steps, you don't have much of a window into how the agent decomposes the task, or what actions it takes. Worse, agents usually keep low-fidelity copies of their own thinking chains, which can drift over long execution times — especially when context is compacted.

Dev-Dash is a hosted task list for your agent, available anywhere, with any coding agent. It provides an external source of truth for your agents to work from. When you create a task in the Dev-Dash UI, Dev-Dash helps you break it down into manageable chunks for any agent to tackle. If you prefer to work directly with your coding agent, Dev-Dash provides instructions to your agent that help it use Dev-Dash in the background, ensuring that your work is tracked and details are preserved no matter what happens to your session.

Task lists become team artifacts, with visibility into what's being worked on and what's up next. Asynchronous agents can automatically work your backlog as your developers focus on high-complexity tasks, all from a shared project.

---

## The Task

The Dev-Dash workflow centers around a single, decomposable unit of work called a **task**. Tasks can have dependencies, sub-tasks, and blocking relationships. While they can vary in size and scope, the lifecycle of a task is simple:

### 1. Create

A task is created with a description of what is to be accomplished. You can create tasks from the Dev-Dash UI, from the CLI (`dd create`), or let your coding agent create them as it plans its work.

### 2. Analyze

The task is analyzed in the Dev-Dash UI, or the coding agent builds a multi-step plan.

- **In the UI:** Dev-Dash will create a detailed description of the task as well as a plan for execution, including files which should be changed. For more complex tasks, Dev-Dash will create a full worktree with subtasks and dependencies, each with detailed instructions.

- **With a coding agent:** The Dev-Dash CLI installs instructions that help your agent interact with Dev-Dash. When your agent is in plan mode, encourage it to utilize sub-issues and dependencies so that your team will have a full view of how the agent plans to proceed. The agent updates the task description with its analysis, making the plan visible to everyone.

### 3. Execute

Once the task has sufficient detail, it's time to execute. Dispatch agents in the Dev-Dash UI to build code in a sandboxed container, or use your local coding agent to do the work.

The installed agent instructions guide your coding agent to mark the task as in progress when work begins, and to close and summarize the work once it is complete. Since Dev-Dash is an external resource, a complex worktree can be followed by an agent even through session compaction or agent disconnects — or can be picked up by a different team member using a different agent.

### 4. Close

When the work is done, the task is closed with a link to the git commit that contains the changes.

---

## What This Gets You

Dev-Dash manages the worktrees and context, allowing agents to scope their work to just what needs to be done. Teams can use any coding agent without losing context or plans. Agent work is tracked and captured instead of lost on compaction. Creating small, focused change sets allows organizations to utilize cheaper models for straightforward tasks while reserving expensive reasoning for the work that needs it.
