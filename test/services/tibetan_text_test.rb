require "test_helper"

class TibetanTextTest < ActiveSupport::TestCase
  test "normalize strips tsheg, shad and whitespace" do
    assert_equal TibetanText.normalize("སྒྲོལ་མ་མཆོད་ཚིག"), TibetanText.normalize("སྒྲོལ མ མཆོད ཚིག།")
  end

  test "normalize returns nil for blank" do
    assert_nil TibetanText.normalize(nil)
    assert_nil TibetanText.normalize("  ")
  end

  test "plausible_tibetan accepts real Uchen titles" do
    assert TibetanText.plausible_tibetan?("མྱུར་མེད་གྲོལ་བའི་ལམ་བཟང་།")
  end

  test "plausible_tibetan rejects Wylie and phonetics" do
    assert_not TibetanText.plausible_tibetan?("sgrol ma mchod tshig bdun ma")
    assert_not TibetanText.plausible_tibetan?("Courtes louanges à Tara")
    assert_not TibetanText.plausible_tibetan?(nil)
  end

  test "plausible_wylie accepts EWTS including Sanskrit capitals" do
    assert TibetanText.plausible_wylie?("sgrol ma la bstod pa")
    assert TibetanText.plausible_wylie?("oM AH hUM badzra gu ru")
    assert TibetanText.plausible_wylie?("myur med grol ba'i lam bzang")
  end

  test "plausible_wylie rejects accented phonetics" do
    assert_not TibetanText.plausible_wylie?("oM gyalwa kungi tchen ngar thoukYé gyalwé")
    assert_not TibetanText.plausible_wylie?("Jétsün Péma drölma")
    assert_not TibetanText.plausible_wylie?(nil)
  end

  test "sanitize_titles keeps a valid triple unchanged" do
    result = TibetanText.sanitize_titles("སྒྲོལ་མ།", "sgrol ma", "Tara")
    assert_equal "སྒྲོལ་མ།", result[:tibetan]
    assert_equal "sgrol ma", result[:wylie]
    assert_equal "Tara", result[:phonetic]
  end

  test "sanitize_titles moves Wylie out of the Tibetan field" do
    result = TibetanText.sanitize_titles("sgrol ma mchod tshig", nil, nil)
    assert_nil result[:tibetan]
    assert_equal "sgrol ma mchod tshig", result[:wylie]
  end

  test "sanitize_titles demotes phonetics found in the Wylie field" do
    result = TibetanText.sanitize_titles(nil, "thoukYé gyalwé youm", nil)
    assert_nil result[:wylie]
    assert_equal "thoukYé gyalwé youm", result[:phonetic]
  end

  test "sanitize_titles drops a non-Tibetan tibetan field without clobbering an existing Wylie" do
    result = TibetanText.sanitize_titles("not tibetan at all", "sgrol ma", "Praises")
    assert_nil result[:tibetan]
    assert_equal "sgrol ma", result[:wylie]
    assert_equal "Praises", result[:phonetic]
  end
end
