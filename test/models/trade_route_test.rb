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
#  index_trade_routes_on_origin_id_and_destination_id     (origin_id,destination_id) UNIQUE
#  index_trade_routes_on_origin_starsystem_id             (origin_starsystem_id)
#  index_trade_routes_on_origin_station_id                (origin_station_id)
#
require 'test_helper'

class TradeRouteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
