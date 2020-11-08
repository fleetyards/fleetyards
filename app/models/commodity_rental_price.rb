# frozen_string_literal: true

# == Schema Information
#
# Table name: commodity_prices
#
#  id                :uuid             not null, primary key
#  confirmed         :boolean          default(FALSE)
#  price             :decimal(15, 2)
#  submitted_by      :uuid
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
class CommodityRentalPrice < CommodityPrice
  enum time_range: { '1-day': 0, '3-days': 1, '7-days': 2, '30-days': 3 }

  after_destroy :update_shop_commodity
  after_save :update_shop_commodity

  validates :time_range, presence: true

  def self.time_range_filters
    CommodityRentalPrice.time_ranges.map do |(item, _index)|
      Filter.new(
        category: 'time_range',
        name: CommodityRentalPrice.human_enum_name(:time_range, item),
        value: item
      )
    end
  end

  def update_shop_commodity
    shop_commodity.update_1_day_prices if time_range == '1-day'
    shop_commodity.update_3_days_prices if time_range == '3-days'
    shop_commodity.update_7_days_prices if time_range == '7-days'
    shop_commodity.update_30_days_prices if time_range == '30-days'
  end
end
