# Phase 04 — Efficient faceted search
Status: PENDING

## Goal
Deliver the "find a prayer instantly knowing it is linked to a master or a deity" experience: faceted, fast, combining catalog metadata with full-text.

## Tasks
- [ ] Facets: master/author, deity, school, language, format — combinable.
- [ ] Combine catalogued metadata with the FTS5 full-text index in a single result flow.
- [ ] Pagination and result ranking; ensure performance on the full corpus (no loading all results into memory — the current search does this).
- [ ] Clear result presentation across the result types (catalogued texts vs raw inventory files).

## Acceptance Criteria
- A prayer can be found quickly by filtering on its master and/or deity.
- Results are paginated and remain responsive on the full corpus.
- Search spans both fully catalogued items and not-yet-catalogued inventory files.

## Decisions Made This Phase
(append as you go)
