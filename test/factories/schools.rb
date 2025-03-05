FactoryBot.define do
  factory :school do
    sequence(:name) { |n| "School #{n}" }

    trait :with_texts do
      after(:create) do |school|
        school.texts << create(:text)
      end
    end
  end
end
