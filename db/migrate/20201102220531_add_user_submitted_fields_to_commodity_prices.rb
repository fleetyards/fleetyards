class AddUserSubmittedFieldsToCommodityPrices < ActiveRecord::Migration[6.0]
  def change
    add_column :commodity_prices, :confirmed, :boolean, default: :false
    add_column :commodity_prices, :submitted_by, :uuid
    add_column :shop_commodities, :confirmed, :boolean, default: :false
    add_column :shop_commodities, :submitted_by, :uuid
  end
end
