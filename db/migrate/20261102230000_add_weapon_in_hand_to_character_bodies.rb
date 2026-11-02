class AddWeaponInHandToCharacterBodies < ActiveRecord::Migration[8.1]
  def change
    add_column :character_bodies, :weapon_in_hand, :jsonb
  end
end
