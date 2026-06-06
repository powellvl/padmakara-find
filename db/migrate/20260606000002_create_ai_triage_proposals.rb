class CreateAiTriageProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_triage_proposals do |t|
      t.references :catalogued_file, null: false, foreign_key: true

      # Proposed catalog metadata
      t.string  :proposed_title_tibetan
      t.string  :proposed_title_wylie
      t.string  :proposed_title_phonetic
      t.string  :proposed_language        # language name, matched to languages table at accept time
      t.boolean :is_prayer_text,  default: true
      t.string  :confidence               # low / medium / high
      t.string  :model_used               # e.g. claude-haiku-4-5 / claude-opus-4-8
      t.text    :ai_notes                 # free-form notes from the model

      # Proposed associations stored as arrays of names (resolved at accept time)
      t.jsonb   :proposed_deity_names,   default: []
      t.jsonb   :proposed_school_names,  default: []
      t.jsonb   :proposed_author_names,  default: []

      # Raw JSON response from the API for auditability
      t.jsonb   :raw_response

      # Review lifecycle: pending_review → accepted | rejected | skipped
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :ai_triage_proposals, :status
    add_index :ai_triage_proposals, :confidence
  end
end
