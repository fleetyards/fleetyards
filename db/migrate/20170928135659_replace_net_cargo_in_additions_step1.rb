class ReplaceNetCargoInAdditionsStep1 < ActiveRecord::Migration[5.1]
  def up
    remove_column :vehicle_additions, :net_cargo
  end

  def down
    add_column :vehicle_additions, :net_cargo, :string
  end
end
