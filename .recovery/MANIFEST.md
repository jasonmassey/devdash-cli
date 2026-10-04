# DevDash Recovery — Session Log Manifest

DevDash production DB was wiped. These JSONL files are the raw Claude Code session logs
that contain the history of dd create/update/close/dep commands needed to recreate the
lost issues.

## Parent recovery tracker (DD Stress Test project — `ce80b310-...`)
- `336b7be7-a806-4e16-8675-f64974a9653a` — Recovery: recreate lost DD issues from session logs (Apr 10-15)

## Target projects for issue recreation
- `dev-dash`        → `896b3dbc-65a8-4ff8-82a3-b8a6a43e64b8` — server/backend
- `devdash-cli`     → `95ca3de0-7e4f-4f9e-9b17-36f5609cfa11` — bash CLI
- `devdash-cli-go`  → `47eb046a-b02a-41b4-926f-8bc7138ab470` — Go CLI rewrite
- `devdash-demo`    → `df59ed50-...` — demo project

## Log files (chronological) — UUID = tracking issue in DD Stress Test

Filename format: `<tracking-uuid>__<project-dir>__<session-id>.jsonl`

| Tracking UUID | Date       | Project            | Session ID       | DD cmds | Status |
|---------------|------------|--------------------|------------------|---------|--------|
| 0f62afda      | 2026-04-10 | dev-dash           | 8cb43c60         | 111     | in_progress — partial recreation done (see RECOVERY_STATE.md) |
| 8d6ca17c      | 2026-04-10 | dev-dash           | dd7369ed         | 1       | pending |
| 23aee464      | 2026-04-10 | dev-dash           | afd8f398         | 1       | pending |
| b69317d2      | 2026-04-11 | dev-dash           | f6919d6f         | 1       | pending |
| 6342504f      | 2026-04-11 | dev-dash           | aa9a98ff         | 1       | pending |
| 6a978511      | 2026-04-11 | devdash-cli-go     | 92795df4         | 6       | pending |
| ad11b644      | 2026-04-12 | dev-dash           | a98e1ed7         | 4       | pending |
| 4fc5bc52      | 2026-04-12 | devdash-cli-go     | d2320a07         | 0       | pending (nothing to recover) |
| 98b09ca1      | 2026-04-12 | dev-dash           | d857fa18         | 68      | pending |
| 5f174331      | 2026-04-12 | devdash-cli-go     | 1a70ae10         | 16      | pending |
| 0f5c31af      | 2026-04-14 | dev-dash           | f825ac8a         | 1       | pending |
| cc45f7a9      | 2026-04-14 | dev-dash           | 6718b67e         | 8       | pending |
| 009dd8e3      | 2026-04-15 | dev-dash           | c05d9be6         | 0       | pending (nothing to recover) |
| 62ca6cc1      | 2026-04-15 | devdash-cli-go     | 0a80f6e6         | 86      | pending |
| 75a25353      | 2026-04-15 | devdash-cli-go     | 30d38627         | 4       | pending |
| 6b01dbb4      | 2026-04-15 | dev-dash           | d992178d         | 12      | pending |
| 87a670f6      | 2026-04-15 | devdash-demo       | b49429cb         | 9       | pending |
| 3560db7e      | 2026-04-15 | devdash-demo       | 10d7935a         | 0       | pending (nothing to recover) |
| 5c848906      | 2026-04-15 | dev-dash           | f032e314         | 32      | pending |
| 71a12133      | 2026-04-15 | dev-dash           | f3d0c2fe         | 183     | pending |
| ec94f2b5      | 2026-04-15 | devdash-cli-go     | b9fa31fe         | 1       | pending |
| 5dd46fa6      | 2026-04-15 | devdash-cli        | 55606f94         | 0       | pending (nothing to recover) |
| 2401d813      | 2026-04-15 | devdash-cli        | 4c7719ca         | 16      | pending (this session — offline-mode work) |

## Extraction approach

For each log:
1. `jq` filter JSONL for `type:"assistant"` entries whose tool_use blocks contain
   `devdash` or `dd ` in `input.command`.
2. Pair each tool_use with its following tool_result to capture returned UUIDs from
   `dd create` commands.
3. Parse `git commit` HEREDOC messages (between `<<'EOF'` and `EOF`) for commit message + SHA.
4. Recreate creates first (parents before children), then closes with `--commit` and `--summary`.

## Rules for the recreation work
- Recreate parent issues first; pass NEW UUIDs (not original) as `--parent=<id>` for children.
- When closing, include `--commit=<sha>` and `--summary="..."` exactly as captured.
- Process logs **chronologically** so later-session closes resolve against issues recreated from earlier sessions.
- Use `DD_PROJECT_ID=<uuid>` prefix — recreate each issue in its original project.
