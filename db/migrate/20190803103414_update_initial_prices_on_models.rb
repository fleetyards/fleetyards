class UpdateInitialPricesOnModels < ActiveRecord::Migration[5.2]
  def up
    Model.find_each do |model|
      model.update(price: ShopCommodity.where(commodity_item_id: model.id, commodity_item_type: 'Model').order(sell_price: :desc).first&.sell_price)
    end
  end

  def down
  end
end
