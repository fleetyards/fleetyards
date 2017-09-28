class ReplaceNetCargoInAdditionsStep2 < ActiveRecord::Migration[5.1]
  def change
    add_column :vehicle_additions, :net_cargo, :integer, default: 0, null: false
  end
end
