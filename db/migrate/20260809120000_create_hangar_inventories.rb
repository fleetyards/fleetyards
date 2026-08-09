# frozen_string_literal: true

class CreateHangarInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :hangar_inventories, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :location
      t.timestamps
    end

    add_index :hangar_inventories, [:user_id, :slug], unique: true
    add_index :hangar_inventories, "user_id, LOWER(name)", unique: true,
      name: "index_hangar_inventories_on_user_id_and_lower_name"
  end
end
