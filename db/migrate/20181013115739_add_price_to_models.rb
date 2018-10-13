class AddPriceToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :price, :decimal, precision: 15, scale: 2
  end
end
