class AddPriceToModelModules < ActiveRecord::Migration[8.1]
  def change
    add_column :model_modules, :price, :decimal, precision: 15, scale: 2
  end
end
