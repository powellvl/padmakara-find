FactoryBot.define do
  factory :text do
    sequence(:title_tibetan) { |n| "༄༅། །བོད་སྐད་ཀྱི་མིང་ #{n}" }
    sequence(:title_phonetics) { |n| "Phonetics #{n}" }
    notes { "Sample notes for this text" }

    trait :with_translations do
      after(:create) do |text|
        create(:translation, text: text, language: create(:language, :english))
        create(:translation, text: text, language: create(:language, :french))
      end
    end

    trait :with_deities do
      after(:create) do |text|
        text.deities << create(:deity)
      end
    end

    trait :with_schools do
      after(:create) do |text|
        text.schools << create(:school)
      end
    end

    trait :with_tags do
      after(:create) do |text|
        text.tags << create(:tag)
      end
    end
  end
end
