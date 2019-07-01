class AddFieldToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :ground, :boolean, default: false
  end
end
