class AddPledgePriceToModelModulePackages < ActiveRecord::Migration[6.1]
  def change
    add_column :model_module_packages, :pledge_price, :decimal, precision: 15, scale: 2
  end
end
