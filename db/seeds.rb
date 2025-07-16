# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

%w[Kagyü Nyingma Gelug Sakya].each do |name|
  School.find_or_create_by!(name: name)
end

[
  "Patrül Rinpoche", "Jamyang Khyentse Wangpo", "Jamyang Khyentse Chökyi Lodrö",
  "Jamgön Kongtrül Lodrö Thayé", "Ngawang Palzang",
  "Kangyur Rinpoche", "Dilgo Khyentse Rinpoche", "Dudjom Rinpoche",
  "Jigme Khyentse Rinpoche", "Pema Wangyal Rinpoche", "Tsongkhapa"
].each do |name|
  Author.find_or_create_by!(name_english: name)
end

[ "Sadhana", "Préliminaires (Ngöndro)", "Entraînement de l'esprit (Lojong)", "Confession", "Protecteurs" ].each do |name|
  Tag.find_or_create_by!(name: name)
end

[ "Shakyamuni Buddha", "Chenrezi", "Amitabha", "Amitayus", "Tara", "Manjushri", "Vajrapani", "Vajrakilaya", "Guru Rinpoche" ].each do |name|
  Deity.find_or_create_by!(name_english: name)
end
