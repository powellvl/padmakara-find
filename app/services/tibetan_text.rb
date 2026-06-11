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
end
