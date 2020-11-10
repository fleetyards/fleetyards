class PrefillConfirmedPrices < ActiveRecord::Migration[6.0]
  def up
    CommodityPrice.update_all(confirmed: true)
    ShopCommodity.update_all(confirmed: true)
  end
end
