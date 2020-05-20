class AddNotifyToVehicles < ActiveRecord::Migration[6.0]
  def change
    add_column :vehicles, :notify, :boolean, default: true
  end
end
