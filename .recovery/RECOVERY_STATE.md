# DevDash Recovery — Work-in-Progress State

## Completed

### Tracking structure (DD Stress Test project, `ce80b310...`)
- Parent: `336b7be7-a806-4e16-8675-f64974a9653a`
- 23 child tracking issues (one per session log) — see MANIFEST.md

### Session 8cb43c60 (Apr 10, dev-dash, 111 dd cmds) — RECREATED
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

Also recreated during the Apr 16 recovery pass:

- Test-coverage children:
  - `629f46c8` -> `4f7a3c84-5387-4f70-850b-1c06faa3ae9d`
  - `032026ff` -> `3e212b1f-2855-436b-a673-33a502824b1a`
  - `9d7c2a78` -> `532e364d-49d0-4122-9d78-38f6363c5ba9`
  - `6ae49b79` -> `93cef329-71d3-4790-b7ad-bfe3ccb0374b`
  - `190293eb` -> `033538be-dbd7-4734-8d4a-a250738be888`
  - `30e71be4` -> `36da25bc-0b29-4e1d-8874-f9d2948220ad`
- Staging children:
  - `d8323374` -> `e90e3b8b-ed64-48a4-8ca5-8cf9b7055b07`
  - `cedc21d4` -> `d1252de0-ea6d-47cc-bf6a-bd901755fd51`
  - `ce308b84` -> `d03269d2-ea0d-4723-b12d-bd1516e8da11`
  - `04145394` -> `d9781f51-d2ad-4c78-8cb5-9b68d36e6431`
  - `60d30762` -> `5cfd76cd-60f0-4a6f-8715-e8c69d4bbdb5`
  - `e6dfd91e` -> `c5cf0ce4-6e0b-4abc-b88e-e07662b3c7d4`
- Async-migration fix:
  - `9fd0e946` -> `cc26c145-8faa-4dfc-b70f-096db5dc1bc7`
- Standalone issues:
  - `4eb16c60` -> `67fa95f2-78d2-489e-b14d-daa0eb6e680b`
  - `17af25e5` -> `850c094c-8eb8-431a-87b7-a3776c989dc1`
  - `2753f9d9` -> `9f1a5a53-ab7c-461f-8441-f4fd84cbb3e3`
  - `5736dac1` -> `0205cfc9-6392-494d-a56f-b275a0169416`
  - `c9dc5d4f` -> `e9f4c006-33e3-4b31-85dd-71d154a4be90`
  - `6836644b` -> `6f04ee6c-0ada-440d-ba85-1ea6f9ad597c`
  - `13de0031` -> `10617212-f3ba-48a0-8fee-3cfb55083d57`
  - `b71f3779` -> `6d1588f1-8c06-4fb7-a9d4-fb38baa7cf08`
  - `2e1c5e79` -> `5cb93a39-71a7-4267-8fe6-13ad1a586f2c`
  - `be7b6bb0` -> `60a0c043-5d57-480c-90c5-29fb56521ceb`
  - `9dc719e0` -> `99d218d7-5a46-49a5-aa94-76de6db32da2`
  - `081e161c` -> `c83fb7b0-1eae-4b83-a19e-e477042658bc`

Recovered closures now applied:

- Closed recreated issues for the JWT fix, Drizzle/schema/ops work, all 63 async-migration children, the async-migration parent, smoke tests, the Postgres test suite, staging flow, migration/export/delta work, board nesting fix, snake_case fix, cutover, cleanup, migration script, the Phase 1 parent, and the CI test Postgres issue.
- The following recreated issues intentionally remain `pending`, matching the original session state:
  - `9f1a5a53-ab7c-461f-8441-f4fd84cbb3e3` (`2753f9d9`) — BeadsTree parent counter bug
  - `99d218d7-5a46-49a5-aa94-76de6db32da2` (`9dc719e0`) — test isolation follow-up
  - `c83fb7b0-1eae-4b83-a19e-e477042658bc` (`081e161c`) — rewrite agent-dispatch.test.ts

## Remaining for session 8cb43c60

None in `dev-dash`. This session's recreated issue tree now respects current server rules:

1. Closed all 63 `Async migration: server/src/...` children first.
2. Then closed `8f125af8-ebd1-4ee2-997b-f45cbee5e08b` (original `720c9e9d`).
3. Then closed `93edd874-2e44-421d-bf15-fd22e9e2502e` (original `673949b7`).

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
