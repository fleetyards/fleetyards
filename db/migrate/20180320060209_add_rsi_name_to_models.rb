class AddRsiNameToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :rsi_name, :string
    add_column :models, :rsi_slug, :string
  end
end
