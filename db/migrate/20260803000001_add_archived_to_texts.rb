class AddArchivedToTexts < ActiveRecord::Migration[8.0]
  def change
    # Un texte dont TOUS les fichiers viennent de dossiers d'archive/travail
    # (obsolètes) : masqué par défaut dans la bibliothèque, jamais supprimé.
    add_column :texts, :archived, :boolean, null: false, default: false
    add_index  :texts, :archived
  end
end
