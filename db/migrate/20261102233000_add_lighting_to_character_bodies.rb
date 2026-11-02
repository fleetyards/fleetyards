class AddLightingToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    add_column :character_bodies, :lighting, :jsonb, null: false, default: []
  end
end
