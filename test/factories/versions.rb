FactoryBot.define do
  factory :version do
    association :translation
    sequence(:name) { |n| "Version #{n}" }
    status { :draft }

    trait :published do
      status { :published }
    end

    trait :reviewing do
      status { :reviewing }
    end

    trait :editing do
      status { :editing }
    end

    trait :reviewing_edition do
      status { :reviewing_edition }
    end

    trait :with_file do
      after(:create) do |version|
        attach_file(version)
      end
    end

    trait :with_files do
      transient do
        files_count { 3 }
      end

      after(:create) do |version, evaluator|
        evaluator.files_count.times do
          attach_file(version)
        end
      end
    end
  end
end

def attach_file(version)
  version.files.attach(
    io: File.open(Rails.root.join("test/fixtures/files/sample.pdf")),
    filename: "sample.pdf",
    content_type: "application/pdf"
  )
end
