# frozen_string_literal: true

# == Schema Information
#
# Table name: trade_routes
#
#  id                              :uuid             not null, primary key
#  average_profit_per_unit         :decimal(15, 2)
#  average_profit_per_unit_percent :decimal(15, 2)
#  profit_per_unit                 :decimal(15, 2)
#  profit_per_unit_percent         :decimal(15, 2)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  destination_celestial_object_id :uuid
#  destination_id                  :uuid
#  destination_starsystem_id       :uuid
#  destination_station_id          :uuid
#  origin_celestial_object_id      :uuid
#  origin_id                       :uuid
#  origin_starsystem_id            :uuid
#  origin_station_id               :uuid
#
# Indexes
#
#  index_trade_routes_on_destination_celestial_object_id  (destination_celestial_object_id)
#  index_trade_routes_on_destination_id                   (destination_id)
#  index_trade_routes_on_destination_starsystem_id        (destination_starsystem_id)
#  index_trade_routes_on_destination_station_id           (destination_station_id)
#  index_trade_routes_on_origin_celestial_object_id       (origin_celestial_object_id)
#  index_trade_routes_on_origin_id                        (origin_id)
#  index_trade_routes_on_origin_id_and_destination_id     (origin_id,destination_id) UNIQUE
#  index_trade_routes_on_origin_starsystem_id             (origin_starsystem_id)
#  index_trade_routes_on_origin_station_id                (origin_station_id)
#
class TradeRoute < ApplicationRecord
  paginates_per 50

  belongs_to :origin_starsystem, class_name: 'Starsystem', optional: true
  belongs_to :origin_celestial_object, class_name: 'CelestialObject', optional: true
  belongs_to :origin_station, class_name: 'Station', optional: true
  belongs_to :destination_starsystem, class_name: 'Starsystem', optional: true
  belongs_to :destination_celestial_object, class_name: 'CelestialObject', optional: true
  belongs_to :destination_station, class_name: 'Station', optional: true

  belongs_to :origin, class_name: 'ShopCommodity'
  belongs_to :destination, class_name: 'ShopCommodity'

  validates :origin, uniqueness: { scope: :destination }

  ransack_alias :commodity, :origin_commodity_item_of_Commodity_type_slug
  ransack_alias :commodity_type, :origin_commodity_item_of_Commodity_type_commodity_type

  before_save :calculate_profit
  before_save :set_location

  def self.with_profit
    where('profit_per_unit > ?', 0)
  end

  def calculate_profit
    self.profit_per_unit = destination.buy_price - origin.sell_price
    self.profit_per_unit_percent = ((100 * (destination.buy_price - origin.sell_price)) / origin.sell_price).round(2)
    self.average_profit_per_unit = destination.average_buy_price - origin.average_sell_price
    self.average_profit_per_unit_percent = ((100 * (destination.average_buy_price - origin.average_sell_price)) / origin.average_sell_price).round(2)
  end

  def set_location
    self.origin_station_id = origin.shop.station_id
    self.origin_starsystem_id = origin.shop.station.starsystem.id
    self.origin_celestial_object_id = origin.shop.station.celestial_object_id
    self.destination_station_id = destination.shop.station_id
    self.destination_starsystem_id = destination.shop.station.starsystem.id
    self.destination_celestial_object_id = destination.shop.station.celestial_object_id
  end
end
