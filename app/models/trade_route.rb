# frozen_string_literal: true

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
  ransack_alias :station, :origin_station_slug_or_destination_station_slug
  ransack_alias :celestial_object, :origin_celestial_object_slug_or_destination_celestial_object_slug
  ransack_alias :starsystem, :origin_starsystem_slug_or_destination_starsystem_slug

  before_save :calculate_profit
  before_save :set_location

  def self.with_profit
    where('profit_per_unit > ?', 0)
  end

  def calculate_profit
    self.profit_per_unit = destination.buy_price - origin.sell_price
    self.profit_per_unit_percent = ((100 * (destination.buy_price - origin.sell_price)) / origin.sell_price).round(2)
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
