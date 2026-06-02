# Phase 02 — Content extraction & full-text search
Status: PENDING

## Goal
Extract the text of every supported file and make the whole corpus full-text searchable — before any manual cataloging — including Tibetan regardless of input method.

## Tasks
- [ ] Per-format extraction: PDF (pdf-reader, already a dependency), Word/docx, and a decision on image OCR (adopt an OCR tool or defer images to a later pass). Store extracted text on the content record.
- [ ] Extraction background job: resumable, tracks status per file (pending / done / failed / unsupported); failures are logged and visible, never silent.
- [ ] SQLite FTS5 index over extracted text + filename, returning result snippets.
- [ ] Tibetan search: index Unicode + Wylie + phonetic forms so a query in any one method finds the file. Note: the existing converters are client-side JS via CDN — running them server-side (JS runtime) or finding Ruby equivalents is a real sub-task to scope here.
- [ ] Search UI over the inventory (filename + content) with snippets, usable before cataloging exists.

## Acceptance Criteria
- Full-text search returns relevant files by their content, not just filename.
- A Tibetan query finds matching files whether typed in Unicode, Wylie, or phonetics.
- Extraction failures are surfaced in the UI/dashboard, not swallowed.

## Decisions Made This Phase
(append as you go)
