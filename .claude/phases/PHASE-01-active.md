# Phase 01 — Inventory
Status: ACTIVE

## Goal
Scan the entire NAS read-only and produce a browsable inventory of every file, identified by content hash, tolerant to files being moved or renamed.

## Tasks
- [x] Establish the Postgres foundation: switch `config/database.yml` to PostgreSQL, enable `pg_trgm` and `pgvector` extensions via migration. Solid* kept on SQLite.
- [x] Make the source root configurable via `NAS_SOURCE_ROOT` env var (`NasSource` initializer). Dev defaults to `tmp/nas_sample` (seeded with sample files).
- [x] Model the content-addressed inventory: `CataloguedFile` (keyed on `sha256_checksum`) + `FileLocation` (path, mtime, last_seen_at, missing_since).
- [x] Introduce the file-reference model (`CataloguedFile` / `FileLocation`). Existing `has_many_attached :files` on `Version` is untouched (Phase 03 concern).
- [x] Scanner background job: `NasScanJob` → `NasScanner` service. Idempotent, read-only, skips re-hashing when size+mtime unchanged.
- [x] Locations not seen in a scan → `missing_since` stamped; `CataloguedFile` row kept forever.
- [x] Inventory dashboard: `/inventory` — format counts, top-folder counts, exact-duplicate list, volume total, scan trigger button.
- [x] Tests: scanner populates; move-file idempotency; duplicates; disappearance; dashboard counts. (Require PostgreSQL to run.)

## Acceptance Criteria
- Running the scanner on a representative subtree fully populates the inventory.
- Moving a file on the NAS and re-scanning updates its location and does not create a second content record.
- The dashboard shows accurate format/folder counts and a correct exact-duplicate list.
- The app provably never writes to the NAS during this phase.

## Decisions Made This Phase

- **2026-06-03** — NAS source root configurable via `NAS_SOURCE_ROOT` env var; defaults to `tmp/nas_sample` in dev. See DECISIONS.md.
- **2026-06-03** — Solid Queue / Cache / Cable remain on SQLite while primary DB moves to PostgreSQL. See DECISIONS.md.
- **2026-06-03** — `CataloguedFile` + `FileLocation` as the content-addressed model. `CataloguedFile` is keyed on `sha256_checksum`; `FileLocation` holds the mutable path + mtime. Missing paths get `missing_since` stamped; their `CataloguedFile` rows are never deleted.
- **2026-06-03** — Scanner skips re-hashing when path + size + mtime are unchanged (performance: avoids I/O on already-indexed files). The stable-check is explicit in `NasScanner#stable?`.
- **2026-06-03** — Content-type inferred from file extension only (no file-content sniffing). Sufficient for Phase 01 counts; Phase 02 can refine when extracting text.
