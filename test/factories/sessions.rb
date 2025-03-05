FactoryBot.define do
  factory :session do
    association :user
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" }
    ip_address { "127.0.0.1" }
  end
end
