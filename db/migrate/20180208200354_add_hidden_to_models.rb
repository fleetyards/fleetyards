class AddHiddenToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :hidden, :boolean, default: false
  end
end
