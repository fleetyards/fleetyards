class AutoConfirmDublicatedPriceSubmissions < ActiveRecord::Migration[6.1]
  def up
    CommodityPrice.where(confirmed: false).find_each do |price|
      submissions = CommodityPrice.where(
        type: price.type,
        shop_commodity_id: price.shop_commodity_id,
        price: price.price,
        time_range: price.time_range
      ).where.not(id: price.id).pluck(:id)

      if submissions.size >= CommodityPrice::REQUIRED_SUBMISSION_COUNT_FOR_AUTO_CONFIRM
        price.confirm
        CommodityPrice.where(id: submissions).update_all(confirmed: true)
      end
    end
  end
end
