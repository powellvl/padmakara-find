FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }

    trait :with_texts do
      after(:create) do |tag|
        tag.texts << create(:text)
      end
    end
  end
end
