FactoryBot.define do
  factory :catalogued_file do
    sequence(:sha256_checksum) { |n| Digest::SHA256.hexdigest("file-content-#{n}") }
    byte_size    { rand(1_000..10_000_000) }
    content_type { "application/pdf" }
    triage_state { :pending }
    first_seen_at { 1.hour.ago }
    last_scan_at  { Time.current }
  end
end
