require "test_helper"

class FolderCatalogApplierTest < ActiveSupport::TestCase
  setup do
    @cf = create(:catalogued_file, extraction_status: :extracted, triage_state: :pending)
    create(:file_location, catalogued_file: @cf, path: "/nas/prayers/Travail/Riwo Sangchö v2.pdf")
  end

  test "rejects generic deity categories and caps the rest" do
    apply(deities: [ "local deities", "gods and ghosts", "Tara", "Chenrezig",
                     "Vajrasattva", "Manjushri", "Lady who Strikes down Malignant Armies" ])

    names = Text.last.deities.map(&:name_english)
    assert_not_includes names, "local deities"
    assert_not_includes names, "gods and ghosts"
    assert_not_includes names, "Lady who Strikes down Malignant Armies"
    assert_operator names.size, :<=, FolderCatalogApplier::MAX_LOOKUPS_PER_KIND
  end

  test "falls back to the file name, never to a work-folder name" do
    apply(title_translated: nil, title_tibetan: nil, title_wylie: nil)

    assert_equal "Riwo Sangchö v2", Text.last.title_phonetics
    assert_not_equal "Travail", Text.last.title_phonetics
  end

  test "keeps a real proposed title untouched" do
    apply(title_translated: "Prière en Sept Vers")
    assert_equal "Prière en Sept Vers", Text.last.title_phonetics
  end

  private

  def apply(title_translated: "Un texte", title_tibetan: nil, title_wylie: nil, deities: [])
    proposal = FolderTriageProposal.create!(
      folder_path: "prayers/Travail", status: :proposed,
      payload: {
        "groups" => [ {
          "title_tibetan" => title_tibetan, "title_wylie" => title_wylie,
          "title_translated" => title_translated, "language" => "French",
          "deities" => deities,
          "files" => [ { "id" => @cf.id, "role" => "version", "version_label" => "v2" } ]
        } ],
        "unassigned_file_ids" => []
      }
    )
    FolderCatalogApplier.new(proposal).call
  end
end
