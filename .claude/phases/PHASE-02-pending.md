# Phase 02 — Content extraction & full-text search
Status: COMPLETE ✓
Validated: 2026-06-04

## Goal
Extract the text of every supported file and make the whole corpus full-text searchable — before any manual cataloging.

## Tasks
- [x] Per-format extraction: PDF (pdf-reader) and Word/docx (rubyzip + nokogiri). Store extracted text on the CataloguedFile record.
- [x] Unsupported formats (images, InDesign, QuarkXPress) → marked `unsupported_format`, not an error.
- [x] OCR deferred — see DECISIONS.md.
- [x] Extraction background job (ExtractTextJob, Solid Queue): resumable, tracks status per file (pending_extraction / extracted / extraction_failed / unsupported_format). Failures logged, never silent.
- [x] PostgreSQL full-text search via `tsvector` + `ts_rank` (supersedes the "FTS5" mention in the original plan — see DECISIONS.md). GIN index on `content_tsvector`. `pg_trgm` index for fuzzy filename matching.
- [x] Tibetan search deferred — see DECISIONS.md.
- [x] Search UI: `/search` now includes CataloguedFile results (filename + content snippet via `ts_headline`), usable before any manual cataloging.
- [x] Inventory dashboard updated with extraction-status breakdown.

## Acceptance Criteria
- [x] Full-text search returns relevant CataloguedFiles by their content, not just filename.
- [x] Extraction failures are surfaced in the inventory dashboard, not swallowed.
- [x] Re-scanning a file whose content has not changed does not re-extract.

## Decisions Made This Phase
- **2026-06-03** — Full-text search uses PostgreSQL `tsvector`/`pg_trgm` with `'simple'` config (no language-specific stemming). OCR and Tibetan search explicitly deferred. See DECISIONS.md.
