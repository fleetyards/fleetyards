class AddScDataFieldsToModelModules < ActiveRecord::Migration[7.1]
  def change
    add_column :model_modules, :cargo, :decimal, precision: 15, scale: 2
    add_column :model_modules, :cargo_holds, :string
  end
end
