# Phase 05 — Naming convention & reversible physical reorganization
Status: PENDING

## Goal
Design a canonical path convention, generate target paths from confirmed metadata, and (only if still warranted) apply physical moves safely and reversibly.

## Precondition
Do not start until the catalog from phases 1–4 has been used for real and we have confirmed a physical reorganization is still needed. The catalog may make a large move unnecessary.

## Tasks
- [ ] Design the path convention with Claude at the *aggregate* level (clusters, naming rules, ambiguous cases) — fed by the metadata already extracted, not file-by-file.
- [ ] Path generator: derive a canonical path deterministically from a file's confirmed metadata, so the tree becomes a projection of the database.
- [ ] Dry-run planner: produce a reviewable "old path → new path" plan that moves nothing.
- [ ] Reversible batched mover: full move log (checksum + old path → new path), backup/snapshot of the old structure kept until validated, batches not big-bang.
- [ ] Package-aware moves: InDesign/QuarkXPress files moved together with their linked assets so documents don't break.
- [ ] Decide and grant the app write access to the NAS (reverses the Phase 01 read-only stance) — log it as its own decision.
- [ ] New-file intake (steady state): drag-and-drop in the web UI → AI proposes metadata + canonical path → human confirms once.

## Acceptance Criteria
- The dry-run produces a complete, reviewable move plan with nothing moved.
- Applying the plan is fully reversible from the move log.
- Moved InDesign/QuarkXPress documents still open with their links intact.
- New files dropped in the UI get an AI-proposed placement the human can accept or edit.

## Decisions Made This Phase
(append as you go)
