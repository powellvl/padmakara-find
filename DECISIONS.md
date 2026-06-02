# Decisions

Architecture decisions for Padmakara-Find. Append-only. Do not edit past entries — add a new one if something changes.

---

## 2026-06-02 — NAS is the single source of truth; the app indexes, it does not store
**Chosen:** The prayer files live only on the NAS. The application is a catalog/index that *points to* files on the NAS. It never copies the originals into its own storage.
**Alternatives:** Make the app the system of record (import every file into Active Storage / object storage), as the current code does via `Version has_many_attached :files`.
**Why:** User decision. There must be exactly one place where a file exists, to avoid divergence between a "NAS copy" and an "app copy". Re-uploading tens of thousands of files by hand is also unrealistic.
**Trade-offs:** The app depends on the NAS being mounted and reachable. The app cannot guarantee a file hasn't changed underneath it between scans (mitigated by checksums). Existing `has_many_attached :files` on `Version` must be replaced by references to indexed files.
**Revisit if:** We ever need the app to serve files when the NAS is offline, or need an immutable archival copy independent of the NAS.

---

## 2026-06-02 — File identity is its content hash, not its path
**Chosen:** A file's identity is the checksum of its content. The path is a mutable "current location" attribute. The catalog is keyed on content (checksum); locations point at it.
**Alternatives:** Key the catalog on the file path (the obvious approach when "the app points to the NAS").
**Why:** The NAS will be reorganized (files moved) in parallel with cataloging. If the catalog were keyed on path, every move would break its entry. Content-addressing (like Git) makes the catalog survive any move: a re-scan sees the same hash at a new path and just updates the location. It also yields exact-duplicate detection for free — a known pain point ("we don't know which is the latest version").
**Trade-offs:** Checksumming tens of thousands of files is I/O-heavy (streamed, run as background jobs, only re-hash when size/mtime changes). The same content at multiple paths needs a one-content → many-locations model.
**Revisit if:** Checksum collisions or hashing cost ever become a practical problem (not expected with a modern hash).

---

## 2026-06-02 — The database is the organization; the folder tree is only physical storage
**Chosen:** The multi-faceted catalog (master/deity/school/language/tag + full-text) is the real organization. The NAS folder tree is just storage and only needs to be *consistent and predictable*, not semantically perfect. Where a physical convention is adopted, canonical paths are *generated from* confirmed metadata so the tree becomes a projection of the database.
**Alternatives:** Invest heavily in designing one "perfect" folder hierarchy and move everything into it.
**Why:** A folder tree can only express one axis at a time, but a prayer is legitimately linked to a master AND a deity AND a school AND a language AND a collection. Any single tree makes the other axes second-class. The database resolves this natively; the tree cannot. So effort goes into the catalog, not into chasing an ideal tree the database makes unnecessary.
**Trade-offs:** Humans browsing the NAS directly (Finder, InDesign) still benefit from a clean tree, so we don't abandon it — we generate it deterministically instead of hand-maintaining it.
**Revisit if:** A workflow emerges that genuinely needs a hand-curated hierarchy the generated convention can't express.

---

## 2026-06-02 — Defer the physical mass-move until the catalog has proven itself; make it reversible
**Chosen:** Build the inventory + catalog + search and *use it for real* before moving any files physically. When/if we do move, it is dry-run first, batched, fully logged (checksum + old path → new path), with a backup of the old structure kept until validated, and InDesign/QuarkXPress files moved together with their linked assets as packages.
**Alternatives:** Reorganize the NAS up front, then build the catalog on the clean tree.
**Why:** Moving a 20-year archive of tens of thousands of files is the single highest-risk, hardest-to-reverse operation in the project. InDesign/QuarkXPress documents reference linked images and fonts by path — moving them blindly breaks documents. Content-addressing protects the *catalog* during a move, but not the *files' internal links*. We may also discover the catalog makes a large physical reorg unnecessary.
**Trade-offs:** The NAS stays messy for humans browsing it directly during phases 1–4. Accepted: findability is delivered by the app in the meantime.
**Revisit if:** Direct-on-NAS browsing becomes a blocking pain before the catalog is mature.

---

## 2026-06-02 — Keep SQLite; use FTS5 for full-text search
**Chosen:** Stay on SQLite. Use its built-in FTS5 extension for full-text search over extracted content and metadata.
**Alternatives:** Migrate to PostgreSQL (+ pg_search); add Elasticsearch/Solr.
**Why:** This is an internal editorial tool with few concurrent writers. SQLite comfortably handles tens of thousands of records; its only real limit is concurrent writes, which this workload doesn't stress. FTS5 gives strong full-text search with zero new infrastructure. Adding Postgres/Elasticsearch now is ops complexity for no current benefit.
**Trade-offs:** No semantic ranking out of the box; concurrent-write ceiling; FTS5 tokenization needs care for Tibetan.
**Revisit if:** We get many simultaneous editors, or search needs outgrow FTS5 (e.g. cross-language semantic search at scale → consider embeddings/vector search, see Phase 3).

---

## 2026-06-02 — AI-assisted triage, always human-in-the-loop
**Chosen:** Use Claude to read extracted content and *propose* catalog metadata (prayer identity, language, title, master/deity/school) and flag near-duplicates. A human confirms or corrects every suggestion before it enters the catalog. Tier models: cheap (Haiku) for bulk, strong (Opus) for ambiguous cases.
**Alternatives:** Fully manual cataloging; or fully automated AI cataloging with no review.
**Why:** Manual cataloging of tens of thousands of files won't scale; fully automated filing of a religious archive is unacceptable for accuracy and trust. AI proposes, human disposes — best of both, and it reuses the existing curation form.
**Trade-offs:** API cost; the review queue is still real human work (but vastly less than from-scratch entry).
**Revisit if:** AI proposals prove either reliable enough to batch-approve, or too noisy to be worth reviewing.

---

## 2026-06-02 — Active Storage is demoted to a cache for derived artifacts only
**Chosen:** Active Storage is kept only for *derived* data the app generates (PDF cover thumbnails, previews). Original files are never stored in it. References to original files move to the new content-addressed file model.
**Alternatives:** Keep using `has_many_attached :files` for originals.
**Why:** Follows from "NAS is the single source of truth". Thumbnails/covers are regenerable, so caching them locally doesn't violate the single-source rule. The existing `ExtractPdfCover` service is reused almost as-is.
**Trade-offs:** The current upload/attach flow on `Version` must be reworked to reference indexed files instead of attaching copies.
**Revisit if:** We decide the app should also archive originals (would reverse the source-of-truth decision).

---

## 2026-06-02 — PostgreSQL over SQLite; all search stays in Postgres (supersedes "Keep SQLite; use FTS5")
**Chosen:** PostgreSQL as the database. Full-text search via `tsvector`/`ts_rank`, fuzzy/typo-tolerant matching via `pg_trgm`, and vector/semantic search via `pgvector` — all inside Postgres. No separate search engine.
**Alternatives:** SQLite + FTS5 (the earlier decision, 2026-06-02); adding Elasticsearch or another dedicated search engine.
**Why:** As scope solidified, three factors outweighed SQLite's operational simplicity: (1) embeddings are central to Phase 3 (near-duplicate detection, later cross-language semantic search) and `pgvector` keeps vectors in the same DB; (2) the "extremely efficient search" goal wants fuzzy matching (`pg_trgm`) and ranked full-text (`tsvector`), both stronger than FTS5; (3) ingestion is write-heavy in bursts (parallel scan + extraction workers), which Postgres handles without SQLite's single-writer serialization. Ops cost is low: Kamal runs Postgres as an accessory container on the same on-prem box. Elasticsearch is rejected as overkill — the corpus is tens of thousands of docs (orders of magnitude below where ES earns its complexity), it adds a heavy JVM service plus a sync pipeline, and it solves neither hard problem (Tibetan tokenization, semantic matching).
**Trade-offs:** One more container to run and back up. The database becomes the most precious asset (curated human work) and needs its own backup (nightly `pg_dump` + off-box copy), independent of the NAS. Tibetan still needs custom tokenization regardless of engine.
**Revisit if:** Search genuinely outgrows Postgres (millions of docs / heavy concurrent query load) — then evaluate a lightweight modern engine (Meilisearch/Typesense) before Elasticsearch.

---

## 2026-06-02 — On-prem application server with LAN-only NAS access
**Chosen:** Run the app on a small on-prem server inside the local network. It mounts the NAS over the LAN and is the only system that touches it; the NAS is never exposed to the internet. Any remote access goes to the app (behind VPN / authenticated reverse proxy), never to the NAS. Target spec: ~4 modern cores, 16 GB RAM, NVMe SSD (~500 GB, for OS/app/DB/thumbnail cache only — originals stay on the NAS), gigabit wired link to the NAS, Linux + Docker/Kamal, no GPU (AI via API).
**Alternatives:** Cloud-hosted app; exposing the NAS directly; a heavily-specced server.
**Why:** User decision on hosting. Keeps the NAS off the public internet by design. The workload is light except for bursty one-off ingestion (I/O-bound NAS reads + extraction/OCR), so standard hardware suffices; the real bottleneck is the NAS↔server network, not CPU. Running AI via API avoids needing a GPU or large RAM for local models.
**Trade-offs:** The app depends on sharing the NAS's network; remote work needs a VPN. A heavier future (local OCR/embeddings at scale, an editorial platform with many concurrent editors) may warrant more RAM/CPU later.
**Revisit if:** Ingestion is unacceptably slow (check the NAS link first), or local AI / large concurrent editing is adopted.

---

## Future direction (not a decision yet — recorded for foresight)
A second-stage editorial platform is intended: line-by-line indexed texts aligned across Tibetan / French / English / Sanskrit, and semi-automatic prayer-booklet generation (select prayers, compile). Prototypes already exist. This is **out of scope** for the catalog work. It will hook in *below* the `Version` (a Version's content gets segmented into aligned lines). Keeping `Version` as the content anchor is enough to avoid foreclosing it; no further design is done now.
