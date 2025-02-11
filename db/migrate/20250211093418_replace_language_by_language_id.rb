class ReplaceLanguageByLanguageId < ActiveRecord::Migration[8.0]
  def up
    Translation.where(language: [ nil, '' ]).update_all(language: 'English')
    add_reference :translations, :language, foreign_key: true
    all_languages = Translation.distinct.pluck(:language)
    all_languages.each do |language_name|
      language = Language.create(name: language_name)
      Translation.where(language: language_name).update_all(language_id: language.id)
    end
    add_index :translations, [ :text_id, :language_id ], unique: true
    remove_column :translations, :language
  end

  def down
    add_column :translations, :language, :string
    Translation.update_all("language = (SELECT name FROM languages WHERE languages.id = translations.language_id)")
    remove_index :translations, [ :text_id, :language_id ]
    remove_column :translations, :language_id
  end
end
