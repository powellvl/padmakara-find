require "json"

# Cross-language consolidation pass: asks a strong model which catalog Texts
# are the same prayer in different languages (or plain duplicates), then merges
# them via TextMergeService.
#
# Needed because per-folder triage reads Tibetan titles independently per file;
# misreadings give the same prayer different titles across languages, which
# string matching cannot reconcile. Semantic title equivalence + folder
# proximity can.
class CatalogConsolidationService
  Result = Data.define(:merges, :errors)

  def initialize(adapter: nil, dry_run: false)
    @adapter = adapter
    @dry_run = dry_run
  end

  def call
    entries = catalog_entries
    return Result.new(merges: [], errors: []) if entries.size < 2

    response = adapter.messages(
      model_tier: :strong,
      max_tokens: 4096,
      system:     system_prompt,
      messages:   [ { role: "user", content: user_prompt(entries) } ]
    )

    sets   = parse_response(response.content.first.text)
    merges = []
    errors = []

    sets.each do |set|
      keep = Text.find_by(id: set["keep_id"])
      next unless keep

      applied_any = false
      Array(set["merge_ids"]).each do |dup_id|
        dup = Text.find_by(id: dup_id)
        next unless dup && dup.id != keep.id

        # Independent visual cross-check of every proposed pair: text-only
        # proposals over-merge thematically related prayers, the covers don't.
        verification = MergeVerificationService.new(keep, dup).call
        unless verification.verdict == :same
          errors << "refus [#{verification.verdict}] ##{dup.id} → ##{keep.id} : #{verification.reason}"
          next
        end

        if @dry_run
          merges << describe(keep, dup, set, verification)
          next
        end

        result = TextMergeService.new(keep, dup).call
        if result.error
          errors << "#{dup_id} → #{set['keep_id']}: #{result.error}"
        else
          merges << describe(keep, dup, set, verification)
          applied_any = true
        end
      end

      apply_canonical_titles(keep, set) if applied_any
    end

    Result.new(merges: merges, errors: errors)
  end

  private

  def adapter
    @adapter ||= AiAdapter.build
  end

  def catalog_entries
    Text.includes(translations: [ :language, { versions: { catalogued_files: :file_locations } } ]).map do |t|
      folders = t.translations.flat_map { |tr|
        tr.versions.flat_map { |v|
          v.catalogued_files.flat_map { |cf|
            cf.file_locations.map { |loc| File.dirname(loc.path).delete_prefix(NasSource.root.to_s) }
          }
        }
      }.uniq.first(3)

      {
        id: t.id,
        title_tibetan: t.title_tibetan,
        title_wylie: t.title_wylie,
        title: t.title_phonetics,
        languages: t.translations.map { |tr| tr.language.name }.uniq,
        deities: t.deities.map(&:name_english).first(2),
        folders: folders
      }.compact
    end
  end

  def system_prompt
    <<~PROMPT
      You are an expert archivist for the Padmakara Translation Group (Tibetan Buddhism).
      Their catalog models one TEXT per prayer, with one TRANSLATION per language.
      Because entries were created folder by folder, the same prayer may appear several
      times: once per language, with diverging or misread Tibetan titles.

      Always respond with a single valid JSON object. Never include prose outside the JSON.
    PROMPT
  end

  def user_prompt(entries)
    <<~PROMPT
      Here are the catalog entries (one JSON object per line):
      #{entries.map(&:to_json).join("\n")}

      Identify sets of entries that are the SAME text: one is a translation of the
      other, or they are duplicate entries for the same work. Judge title equivalence
      semantically (e.g. "Courtes louanges à la Vénérable Tara" ≈ "Short praises to
      exalted Tara"). Tibetan titles may disagree because one was misread — that alone
      must not prevent a merge when the translated titles clearly match.

      STRICT RULES — a merge is allowed ONLY when the titles are translations of each
      other or near-identical. The following are NEVER sufficient reasons to merge:
      - prayers addressed to the same deity or person
      - texts by the same author
      - texts in the same folder or compiled in the same booklet
      - titles that are "related", "complementary", or "variants of a theme"
      If two entries are different prayers — even close ones — they must stay separate.
      Evaluate each merge pairwise against the keep entry; do not build large sets by
      theme.

      For each set, pick keep_id = the entry whose Tibetan title looks most plausible
      (real Tibetan script, coherent Wylie), optionally provide the canonical
      Tibetan/Wylie title, and rate your confidence:
      - "high"   — titles are clear translations of each other / same work, no doubt
      - "medium" — probably the same work but one signal is weak
      - "low"    — speculative

      Return ONLY this JSON:
      {
        "merge_sets": [
          {
            "keep_id": 0,
            "merge_ids": [0],
            "title_tibetan": "canonical Tibetan title or null",
            "title_wylie": "canonical Wylie or null",
            "confidence": "high|medium|low",
            "reason": "short justification"
          }
        ]
      }
      Return {"merge_sets": []} if nothing should be merged.
    PROMPT
  end

  def apply_canonical_titles(keep, set)
    titles = TibetanText.sanitize_titles(set["title_tibetan"], set["title_wylie"])

    if titles[:tibetan]
      keep.title_tibetan            = titles[:tibetan]
      keep.title_tibetan_normalized = TibetanText.normalize(titles[:tibetan])
    end
    keep.title_wylie = titles[:wylie] if titles[:wylie]
    keep.save! if keep.changed?
  end

  def describe(keep, dup, set, verification)
    "##{dup.id} (#{dup.title_phonetics || dup.title_wylie}) → ##{keep.id} (#{keep.title_phonetics || keep.title_wylie}) — vision: #{verification.reason}"
  end

  def parse_response(raw_text)
    clean = raw_text.gsub(/```(?:json)?\n?/, "").strip
    Array(JSON.parse(clean)["merge_sets"])
  rescue JSON::ParserError
    []
  end
end
