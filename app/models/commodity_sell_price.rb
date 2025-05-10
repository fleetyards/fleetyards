# frozen_string_literal: true

# == Schema Information
#
# Table name: commodity_prices
#
#  id                :uuid             not null, primary key
#  confirmed         :boolean          default(FALSE)
#  price             :decimal(15, 2)
#  submission_count  :integer          default(0)
#  submitters        :string
#  time_range        :integer
#  type              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  shop_commodity_id :uuid
#
# Indexes
#
#  index_commodity_prices_on_shop_commodity_id  (shop_commodity_id)
#
class CommoditySellPrice < CommodityPrice
  after_destroy :update_shop_commodity
  after_save :update_shop_commodity

  def update_shop_commodity
    return if shop_commodity.blank?

    shop_commodity.update_sell_prices
  end
end
