# frozen_string_literal: true

# == Schema Information
#
# Table name: trade_routes
#
#  id                           :uuid             not null, primary key
#  container_sizes              :integer          default([]), not null, is an Array
#  container_sizes_destination  :integer          default([]), not null, is an Array
#  container_sizes_origin       :integer          default([]), not null, is an Array
#  destination_price_updated_at :datetime
#  distance                     :decimal(10, 2)
#  origin_price_updated_at      :datetime
#  price_destination            :decimal(15, 2)   not null
#  price_origin                 :decimal(15, 2)   not null
#  scu_destination              :integer          default(0), not null
#  scu_origin                   :integer          default(0), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  commodity_id                 :uuid             not null
#  destination_terminal_id      :uuid             not null
#  origin_terminal_id           :uuid             not null
#
# Indexes
#
#  index_trade_routes_on_commodity_and_terminals  (commodity_id,origin_terminal_id,destination_terminal_id) UNIQUE
#  index_trade_routes_on_commodity_id             (commodity_id)
#  index_trade_routes_on_destination_terminal_id  (destination_terminal_id)
#  index_trade_routes_on_origin_terminal_id       (origin_terminal_id)
#
# Foreign Keys
#
#  fk_rails_...  (commodity_id => commodities.id) ON DELETE => cascade
#  fk_rails_...  (destination_terminal_id => terminals.id) ON DELETE => cascade
#  fk_rails_...  (origin_terminal_id => terminals.id) ON DELETE => cascade
#
class TradeRoute < ApplicationRecord
  belongs_to :commodity
  belongs_to :origin_terminal, class_name: "Terminal"
  belongs_to :destination_terminal, class_name: "Terminal"

  paginates_per 50

  DEFAULT_SORTING_PARAMS = ["profit_per_scu desc"]
  DEFAULT_SHIP_SORTING_PARAMS = ["profit_per_run desc"]

  # Only meaningful once a ship says how much fits; without one they fall back
  # to the default.
  SHIP_SORTING_PARAMS = [
    "profitPerRun asc", "profitPerRun desc",
    "profitPerDistance asc", "profitPerDistance desc"
  ]

  ALLOWED_SORTING_PARAMS = [
    "profitPerScu asc", "profitPerScu desc",
    "distance asc", "distance desc",
    *SHIP_SORTING_PARAMS
  ]

  # Subqueries rather than joins, which would leave ransack's own joins on the
  # same table to guess the aliases.
  scope :between_available_terminals, -> {
    where(origin_terminal_id: Terminal.available.select(:id), destination_terminal_id: Terminal.available.select(:id))
  }

  # A route is only as fresh as the older of its two prices.
  scope :priced_within, ->(age) {
    cutoff = age.ago
    where(origin_price_updated_at: cutoff.., destination_price_updated_at: cutoff..)
  }

  LOAD_LIMITS = %w[hold stock demand budget].freeze
  UNFLYABLE_REASONS = %w[origin destination both].freeze

  def self.ransackable_attributes(_auth_object = nil)
    %w[commodity_id origin_terminal_id destination_terminal_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[commodity origin_terminal destination_terminal]
  end

  def profit_per_scu
    price_destination - price_origin
  end
end
