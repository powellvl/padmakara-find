# Phase 03 — AI-assisted triage & cataloging
Status: PENDING

## Goal
For each un-catalogued file, have Claude propose catalog metadata and near-duplicate links; a human confirms or corrects each suggestion into the Text → Translation → Version model.

## Tasks
- [ ] Integrate the Claude API with tiered models: cheap model for bulk triage, strong model for ambiguous cases.
- [ ] Per-file proposal: prayer identity, language, title (Tibetan / Wylie / phonetic), candidate master/deity/school, with a confidence signal.
- [ ] Near-duplicate clustering via embeddings (same prayer, different wording — what checksums cannot catch).
- [ ] Review-queue UI: show the AI proposal, let the human confirm/edit, then create or link Text → Translation → Version and mark the file as catalogued (set its version reference). Reuse the existing text/curation form.
- [ ] Rework `Version` to reference indexed files instead of `has_many_attached :files`; keep Active Storage only for derived covers/thumbnails (reuse `ExtractPdfCover`).
- [ ] Tests covering: file goes from untriaged → linked to a Version; near-duplicate clusters surface; nothing is auto-committed without human confirmation.

## Acceptance Criteria
- A file can move from "untriaged" to "linked to a Version" in a few clicks.
- Near-duplicate clusters are surfaced to the reviewer.
- The human is always in the loop — no metadata enters the catalog without confirmation.

## Decisions Made This Phase
(append as you go)
