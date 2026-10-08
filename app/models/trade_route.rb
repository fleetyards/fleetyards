# frozen_string_literal: true

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
