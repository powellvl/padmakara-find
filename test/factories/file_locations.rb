FactoryBot.define do
  factory :file_location do
    association :catalogued_file
    sequence(:path) { |n| "/nas/prayers/folder_#{n}/file_#{n}.pdf" }
    mtime         { 1.hour.ago }
    last_seen_at  { Time.current }
    missing_since { nil }

    trait :missing do
      missing_since { 30.minutes.ago }
    end
  end
end
