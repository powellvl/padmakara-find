FactoryBot.define do
  factory :deity do
    sequence(:name_tibetan) { |n| "བོད་སྐད་ཀྱི་ལྷ་ #{n}" }
    sequence(:name_sanskrit) { |n| "Sanskrit Deity #{n}" }
    sequence(:name_english) { |n| "English Deity #{n}" }

    trait :with_texts do
      after(:create) do |deity|
        deity.texts << create(:text)
      end
    end
  end
end
