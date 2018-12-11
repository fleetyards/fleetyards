class AddPledgePriceToModelModules < ActiveRecord::Migration[5.2]
  def change
    add_column :model_modules, :pledge_price, :decimal, precision: 15, scale: 2
  end
end
