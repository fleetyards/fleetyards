class AddFieldsToVehicles < ActiveRecord::Migration[5.1]
  def change
    add_column :vehicles, :flagship, :boolean, default: false
  end
end
