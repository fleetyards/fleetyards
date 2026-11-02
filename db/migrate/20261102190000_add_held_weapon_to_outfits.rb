class AddHeldWeaponToOutfits < ActiveRecord::Migration[8.1]
  def change
    add_column :outfits, :held_weapon, :string
  end
end
