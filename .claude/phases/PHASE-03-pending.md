# Phase 03 — AI-assisted triage & cataloging
Status: COMPLETE ✓
Validated: 2026-06-07

## Goal
For each un-catalogued file, have Claude propose catalog metadata and near-duplicate links; a human confirms or corrects each suggestion into the Text → Translation → Version model.

## Tasks
- [x] Integrate the Claude API with tiered models: claude-haiku-4-5 for bulk, claude-opus-4-8 for low-confidence re-runs.
- [x] Per-file proposal: prayer identity, language, title (Tibetan / Wylie / phonetic), candidate master/deity/school, with a confidence signal.
- [x] Near-duplicate clustering via pg_trgm similarity on extracted_text (embeddings deferred — see DECISIONS.md).
- [x] Review-queue UI: show the AI proposal, let the human confirm/edit, then create or link Text → Translation → Version and mark the file as catalogued (set its version reference). Reuses Language/Deity/School/Author lookup.
- [x] CataloguedFile gets a nullable version_id FK (linked after triage). Version gets has_many :catalogued_files.
- [x] has_many_attached :files on Version kept for backward compatibility; new files go through catalogued_files. Full removal deferred.
- [x] Tests covering: file goes from untriaged → linked to a Version; near-duplicate clusters surface; nothing is auto-committed without human confirmation.

## Acceptance Criteria
- [x] A file can move from "untriaged" to "linked to a Version" in a few clicks.
- [x] Near-duplicate clusters are surfaced to the reviewer.
- [x] The human is always in the loop — no metadata enters the catalog without confirmation.

## Decisions Made This Phase
- **2026-06-06** — Near-duplicate detection uses pg_trgm similarity (not embeddings). Embeddings deferred until an embedding API is chosen. See DECISIONS.md.
- **2026-06-06** — AiTriageService client injected via constructor for testability (avoids ENV.fetch at init time). Fake client used for local validation without API key.
- **2026-06-06** — has_many_attached :files kept on Version for backward compat. Full removal scheduled for a future cleanup phase.
