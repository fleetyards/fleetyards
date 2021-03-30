# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_commodities
#
#  id                           :uuid             not null, primary key
#  average_buy_price            :decimal(15, 2)
#  average_rental_price_1_day   :decimal(15, 2)
#  average_rental_price_30_days :decimal(15, 2)
#  average_rental_price_3_days  :decimal(15, 2)
#  average_rental_price_7_days  :decimal(15, 2)
#  average_sell_price           :decimal(15, 2)
#  buy_price                    :decimal(15, 2)
#  commodity_item_type          :string
#  confirmed                    :boolean          default(FALSE)
#  price_per_unit               :boolean          default(FALSE)
#  rental_price_1_day           :decimal(15, 2)
#  rental_price_30_days         :decimal(15, 2)
#  rental_price_3_days          :decimal(15, 2)
#  rental_price_7_days          :decimal(15, 2)
#  sell_price                   :decimal(15, 2)
#  submitted_by                 :uuid
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  commodity_item_id            :uuid
#  shop_id                      :uuid
#
# Indexes
#
#  index_shop_commodities_on_commodity_item_id      (commodity_item_id)
#  index_shop_commodities_on_item_type_and_item_id  (commodity_item_type,commodity_item_id)
#  index_shop_commodities_on_shop_id                (shop_id)
#
require 'test_helper'

class ShopCommodityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
