FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "Language #{n}" }

    trait :english do
      name { "English" }
    end

    trait :french do
      name { "French" }
    end

    trait :tibetan do
      name { "Tibetan" }
    end
  end
end
