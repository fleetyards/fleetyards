class AddRsiChassisIdToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :rsi_chassis_id, :integer
  end
end
