# Padmakara Find

Internal document catalog for **Padmakara**, a Buddhist text publishing
association. The app indexes the association's NAS and turns a flat folder tree
into a searchable catalog: the secretariat finds documents, translators find and
work on the files they need, and the whole archive stays organised in one place.

Built with Ruby on Rails 8 during a work-study placement, and still maintained.

---

## The core idea

**The NAS stays the single source of truth — the app indexes, it never stores.**

Files are identified by their **SHA-256 checksum**, not by their path. A file that
moves is still the same file; two copies in two folders are one catalogued file
with two locations. That makes the physical folder tree irrelevant to the
organisation: the database becomes the structure, the NAS is only storage.

Every architectural decision behind this is written down in
[`DECISIONS.md`](DECISIONS.md), with dates and the reasoning that led to it —
including the ones that were later superseded.

## Features

- **Full-text search** over the catalog, using PostgreSQL `tsvector` / `pg_trgm`.
- **NAS indexing** — a scan records each file's checksum, size, content type and
  every path it is currently seen at. Locations that disappear are flagged with a
  `missing_since` date instead of being deleted, so nothing is silently lost.
- **Duplicate detection** — a file present at several active locations is
  surfaced as a duplicate.
- **Cataloguing model** for the publishing domain: texts (Tibetan, Wylie and
  phonetic titles), translations, versions, authors, schools, deities, languages
  and free tagging.
- **AI-assisted triage, human-in-the-loop** — proposals carry a confidence level
  and are always reviewed by a person before anything is applied.
- **Authentication and admin area** — sessions, password reset, user management.

## Data model

Around twenty tables. The ones that carry the design:

| Table | Purpose |
|---|---|
| `catalogued_files` | one row per unique file content — checksum, size, type, scan timestamps |
| `file_locations` | every path where that content is seen — `mtime`, `last_seen_at`, `missing_since` |
| `texts` | catalogued work — Tibetan, Wylie and phonetic titles, notes |
| `translations` / `versions` | translation work and successive versions of a text |
| `authors` · `schools` · `deities` · `languages` | classification, joined to texts |
| `tags` / `taggings` | free tagging |
| `ai_triage_proposals` | AI suggestion for a file, with status and confidence |
| `users` / `sessions` | authentication |

The split between `catalogued_files` and `file_locations` is the heart of it:
content identity on one side, physical placement on the other.

## Stack

- Ruby 3.4 · Rails 8.0
- PostgreSQL (+ `pgvector`) — full-text search stays in the database
- Solid Queue / Solid Cache / Solid Cable
- Hotwire (Turbo, Stimulus) · Tailwind CSS
- Kamal for deployment, on-premises with LAN-only NAS access

## Getting started

```bash
git clone https://github.com/powellvl/padmakara-find.git
cd padmakara-find
bin/setup

bin/rails db:prepare
bin/dev
```

The NAS source root is configurable — point it at a local sample tree in
development rather than the real share (see `DECISIONS.md`).

Tests and checks:

```bash
bin/rails test           # model tests
bin/rails test:system    # system tests
bin/brakeman --no-pager  # security scan
bin/rubocop              # linting
```

CI runs the security scans, the linter and the test suite on every push and pull
request.

## Status

Internal tool, in use by the association. Next steps recorded in `DECISIONS.md`
include OCR and Tibetan-script search, both deliberately deferred.
