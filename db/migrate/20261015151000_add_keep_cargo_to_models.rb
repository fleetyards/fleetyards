# frozen_string_literal: true

# For a ship whose game-file version is not the one sold -- a temporary NPC
# stand-in, say -- the cargo an admin entered stands instead of the holds.
class AddKeepCargoToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :keep_cargo, :boolean, null: false, default: false
  end
end
