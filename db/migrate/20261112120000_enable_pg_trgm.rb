# frozen_string_literal: true

# Trigram similarity, for a search that still finds a name typed with a letter
# off.
class EnablePgTrgm < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"
  end
end
