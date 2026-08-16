# frozen_string_literal: true

class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories, id: :uuid do |t|
      t.references :holder, type: :uuid, polymorphic: true, null: false, index: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :location
      t.timestamps
    end

    add_index :inventories, [:holder_type, :holder_id]
    add_index :inventories, [:holder_type, :holder_id, :slug], unique: true
    add_index :inventories, "holder_type, holder_id, LOWER(name)", unique: true,
      name: "index_inventories_on_holder_and_lower_name"
  end
end
