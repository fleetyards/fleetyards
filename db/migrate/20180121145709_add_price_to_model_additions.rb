class AddPriceToModelAdditions < ActiveRecord::Migration[5.1]
  def change
    add_column :model_additions, :price, :decimal, precision: 15, scale: 2, default: nil, null: true
  end
end
