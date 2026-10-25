# frozen_string_literal: true

# Versions of one item -- a weapon and its skins, a garment in each colour --
# share a key the parser derives from their record keys. On the row rather than
# the build: it identifies the item the way `sc_key` does.
class AddFamilyKeyToEquipment < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :family_key, :string
    add_index :equipment, :family_key
  end
end
