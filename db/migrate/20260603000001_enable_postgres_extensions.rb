class EnablePostgresExtensions < ActiveRecord::Migration[8.0]
  def up
    enable_extension "pg_trgm"
    enable_extension "vector"
  end

  def down
    disable_extension "vector"
    disable_extension "pg_trgm"
  end
end
