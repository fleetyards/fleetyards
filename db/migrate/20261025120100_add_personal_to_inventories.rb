# frozen_string_literal: true

class AddPersonalToInventories < ActiveRecord::Migration[8.1]
  def change
    add_column :inventories, :personal, :boolean, default: false, null: false
    add_index :inventories, [:holder_type, :holder_id], unique: true, where: "personal",
      name: "index_inventories_on_holder_personal"
  end
end
