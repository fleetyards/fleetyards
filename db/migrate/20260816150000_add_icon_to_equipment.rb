class AddIconToEquipment < ActiveRecord::Migration[8.1]
  def change
    # The path the record names, not an asset we hold: the export carries no
    # textures yet, so this resolves to nothing until it does.
    add_column :equipment, :icon, :string
  end
end
