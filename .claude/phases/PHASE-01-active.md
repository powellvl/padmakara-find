# Phase 01 — Inventory
Status: ACTIVE

## Goal
Scan the entire NAS read-only and produce a browsable inventory of every file, identified by content hash, tolerant to files being moved or renamed.

## Tasks
- [ ] Establish the Postgres foundation (supersedes the old SQLite default — see DECISIONS.md, "PostgreSQL over SQLite"): switch `config/database.yml` to PostgreSQL, run Postgres as a Kamal accessory, enable the `pg_trgm` and `pgvector` extensions. Keep the Solid* (cache/queue/cable) stack working.
- [ ] Mount the NAS read-only on the server; make the root path(s) configurable. The app must never write to the NAS in this phase.
- [ ] Model the content-addressed inventory: one record per unique content (keyed on checksum) with size, content_type, and triage state; a separate location record (path, mtime, last_seen_at) so the same content can exist at many paths.
- [ ] Replace the assumption that files are Active Storage attachments: introduce the file-reference model that later phases and `Version` will link to. (Do not yet rip out the existing `has_many_attached :files` — that happens in Phase 03 when linking files to versions.)
- [ ] Scanner background job (Solid Queue): walk the tree, stream-checksum each file (only re-hash when size/mtime changed), upsert content by checksum, upsert location by path, stamp last_seen_at. Idempotent and re-runnable.
- [ ] Detect locations not seen in the latest run → mark as moved/deleted rather than dropping the catalog entry.
- [ ] Inventory dashboard: total volume, counts by format, counts by top-level folder, and exact-duplicate list (content present at more than one location).
- [ ] Tests: scanner populates correctly; re-running after moving a file updates the location without duplicating the content record; dashboard counts are accurate.

## Acceptance Criteria
- Running the scanner on a representative subtree fully populates the inventory.
- Moving a file on the NAS and re-scanning updates its location and does not create a second content record.
- The dashboard shows accurate format/folder counts and a correct exact-duplicate list.
- The app provably never writes to the NAS during this phase.

## Decisions Made This Phase
(append as you go)
