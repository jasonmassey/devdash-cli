# DevDash Recovery — Work-in-Progress State

## Completed

### Tracking structure (DD Stress Test project, `ce80b310...`)
- Parent: `336b7be7-a806-4e16-8675-f64974a9653a`
- 23 child tracking issues (one per session log) — see MANIFEST.md

### Session 8cb43c60 (Apr 10, dev-dash, 111 dd cmds) — PARTIAL RECREATION
Tracking bead: `0f62afda` (in_progress).

Recreated in `dev-dash` project (896b3dbc) with these NEW UUIDs:

| Original UUID | New UUID | Title |
|---------------|----------|-------|
| 673949b7 | `93edd874-2e44-421d-bf15-fd22e9e2502e` | Phase 1: Migrate SQLite to Postgres (parent) |
| 5c136a69 | `c722699b-505b-424e-8925-58f660581931` | Install Drizzle ORM + pg driver |
| c38637d9 | `843d153e-6bc7-4ac2-9ddf-0ccec0a2088b` | Define Drizzle schema for all 36 tables |
| 23bfac86 | `5457be70-4633-4f8f-b498-61cb24fe4ee2` | Rewrite ops layer to async Postgres |
| 720c9e9d | `8f125af8-ebd1-4ee2-997b-f45cbee5e08b` | Update 68 consuming files to async DB calls |
| b92d1ff2 | `1e64c71f-ec0c-4070-9b47-47f8192c5801` | Create SQLite-to-Postgres data migration script |
| f8075aeb | `ffd5a7b5-1fed-4528-805a-5b2d683df093` | Smoke test ops layer against Railway Postgres |
| 0743a365 | `99262e52-f70b-4feb-a8fc-6888bd318309` | Phase 1b: Postgres migration test coverage |
| d508daac | `08640c93-9b7d-4aa2-963f-407621e85e8e` | Set up Railway staging environment |

**Plus 63 async-migration grandchildren** under the new `8f125af8` parent (all titled
`Async migration: server/src/<path>.ts`). Paths listed in ANALYSIS_8cb43c60.md.

## Remaining for session 8cb43c60

Still TO CREATE in `dev-dash` (896b3dbc):
- 6 test-coverage grandchildren under `99262e52-f70b-4feb-a8fc-6888bd318309` (original UUIDs: 629f46c8, 032026ff, 9d7c2a78, 6ae49b79, 190293eb, 30e71be4)
- 6 staging grandchildren under `08640c93-9b7d-4aa2-963f-407621e85e8e` (original UUIDs: d8323374, cedc21d4, ce308b84, 04145394, 60d30762, e6dfd91e)
- 1 fix issue under `8f125af8-ebd1-4ee2-997b-f45cbee5e08b` (original UUID: 9fd0e946)
- 12 standalone issues (original UUIDs: 4eb16c60, 17af25e5, 2753f9d9, 5736dac1, c9dc5d4f, 6836644b, 13de0031, b71f3779, 2e1c5e79, be7b6bb0, 9dc719e0, 081e161c)

Still TO CLOSE: ~35 issues (see ANALYSIS_8cb43c60.md section 5 for commit SHAs and summaries).

## Remaining logs to process (chronological)

Sessions 2-23 have not been started. See MANIFEST.md for the full list.

- Sessions with 0 dd commands can be closed-out immediately without recreation work: `4fc5bc52`, `009dd8e3`, `3560db7e`, `5dd46fa6`.
- Session `2401d813` (this session) created 5 beads in `devdash-cli-go` (47eb046a) for an offline-mode feature plan:
  - Parent: "Build offline mode with local task caching" (original UUID `fcd2538a`, **RE-CREATED** at `e038c114-9782-4784-918d-a709391bb83c`)
  - Children (NOT YET recreated): `167880db`, `ab7c3144`, `9c89faa6`, `047397e4` — see session log for titles/descriptions.

## How to continue

1. For each remaining log, use `jq` to extract dd commands (see MANIFEST.md approach).
2. Recreate parents before children.
3. Capture new UUIDs and update a mapping as you go.
4. Close issues with `--commit` and `--summary` from the log.
5. Update the corresponding tracking bead status when a log is fully processed.
