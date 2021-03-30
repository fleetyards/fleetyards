class ChangeColumnDefaultForVehicles < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:vehicles, :public, false)
  end
end
