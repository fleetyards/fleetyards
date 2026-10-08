# frozen_string_literal: true

class Terminal < ApplicationRecord
  # The place the terminal is at, matched by name during the UEX sync. Empty
  # for a terminal at a place the starmap does not carry -- Port Olisar, gone
  # from the game, or a terminal UEX names no place for.
  belongs_to :location, optional: true

  has_many :item_prices, dependent: :nullify
  has_many :origin_trade_routes, class_name: "TradeRoute", foreign_key: :origin_terminal_id, dependent: :delete_all, inverse_of: :origin_terminal
  has_many :destination_trade_routes, class_name: "TradeRoute", foreign_key: :destination_terminal_id, dependent: :delete_all, inverse_of: :destination_terminal

  validates :uex_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :contact_url, format: {with: %r{\Ahttps?://}}, allow_blank: true

  scope :available, -> { where(available: true) }

  # On a planet or moon rather than at a station. UEX names the parent body in
  # `orbit` for both, so only the kind of place tells them apart. A terminal
  # with no place recorded counts as neither: nothing says a ship can't reach it.
  SURFACE_SQL = "(%<table>s.space_station IS NULL AND (%<table>s.city IS NOT NULL OR %<table>s.outpost IS NOT NULL))"

  scope :on_surface, -> { where(format(SURFACE_SQL, table: table_name)) }

  def on_surface?
    space_station.blank? && (city.present? || outpost.present?)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id star_system planet]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
