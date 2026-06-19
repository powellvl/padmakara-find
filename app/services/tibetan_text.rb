# Normalisation helpers for Tibetan titles used as cross-language join keys.
#
# The same title can be written with varying tsheg/space/shad usage depending on
# the source document, so the matching key strips separators and punctuation.
# The display form keeps the original string.
module TibetanText
  # Tsheg, shad variants, and other Tibetan punctuation irrelevant to identity.
  PUNCTUATION = /[\s་༌།༎༏༐༑༔༵༶༸༺༻༼༽]/

  def self.normalize(title)
    return nil if title.blank?

    key = title.unicode_normalize(:nfc).gsub(PUNCTUATION, "")
    key.presence
  end

  # A plausible Tibetan title is mostly Tibetan script. AI models sometimes
  # "transliterate" a phonetic title INTO Tibetan letters or return Wylie in
  # the Tibetan field; both poison the cross-language join key.
  def self.plausible_tibetan?(str)
    return false if str.blank?

    chars = str.gsub(/\s/, "").chars
    return false if chars.empty?

    chars.count { |c| c.match?(/\p{Tibetan}/) }.fdiv(chars.size) >= 0.9
  end

  # Wylie (EWTS) is pure ASCII — capitals are legitimate (Sanskrit: "oM AH hUM")
  # but accented latin ("thoukYé gyalwé") is phonetics masquerading as Wylie.
  def self.plausible_wylie?(str)
    return false if str.blank?

    str.ascii_only? && str.match?(/[a-z]/)
  end

  # Returns {tibetan:, wylie:, phonetic:} with each value in the right field:
  # implausible Tibetan is dropped (or moved to Wylie if it is ASCII), fake
  # Wylie is demoted to phonetic. Never invents, only reclassifies or drops.
  def self.sanitize_titles(tibetan, wylie, phonetic = nil)
    tib = tibetan.presence
    wyl = wylie.presence
    pho = phonetic.presence

    unless tib.nil? || plausible_tibetan?(tib)
      wyl ||= tib if plausible_wylie?(tib)
      tib = nil
    end

    unless wyl.nil? || plausible_wylie?(wyl)
      pho ||= wyl
      wyl = nil
    end

    { tibetan: tib, wylie: wyl, phonetic: pho }
  end
end
