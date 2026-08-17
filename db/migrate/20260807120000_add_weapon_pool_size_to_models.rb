class AddWeaponPoolSizeToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :weapon_pool_size, :integer
  end
end
