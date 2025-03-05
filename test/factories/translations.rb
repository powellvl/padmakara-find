FactoryBot.define do
  factory :translation do
    association :text
    association :language

    trait :english do
      association :language, factory: [ :language, :english ]
    end

    trait :french do
      association :language, factory: [ :language, :french ]
    end

    trait :with_title do
      transient do
        title { "Translation Title" }
      end

      # Since 'title' is not a database column but was in fixtures,
      # we can add it as a transient attribute for test compatibility
    end
  end
end
