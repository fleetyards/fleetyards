class AddBoughtViaToVehicles < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicles, :bought_via, :integer, default: 0
  end
end
