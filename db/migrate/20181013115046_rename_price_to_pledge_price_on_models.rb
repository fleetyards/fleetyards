class RenamePriceToPledgePriceOnModels < ActiveRecord::Migration[5.2]
  def change
    rename_column :models, :price, :pledge_price
    rename_column :models, :fallback_price, :fallback_pledge_price
  end
end
