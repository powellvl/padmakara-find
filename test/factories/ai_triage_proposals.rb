FactoryBot.define do
  factory :ai_triage_proposal do
    association :catalogued_file
    proposed_title_tibetan  { "སྒྲོལ་མའི་མཆོད་པ།" }
    proposed_title_wylie    { "sgrol ma'i mchod pa" }
    proposed_title_phonetic { "Tara Puja" }
    proposed_language       { "French" }
    is_prayer_text          { true }
    proposed_deity_names    { ["Tara"] }
    proposed_school_names   { ["Nyingma"] }
    proposed_author_names   { [] }
    confidence              { "medium" }
    model_used              { "claude-haiku-4-5-20251001" }
    raw_response            { { text: "{}" } }
    status                  { :pending_review }

    trait :accepted do
      status { :accepted }
    end

    trait :low_confidence do
      confidence { "low" }
    end
  end
end
