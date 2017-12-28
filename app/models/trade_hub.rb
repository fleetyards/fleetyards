# frozen_string_literal: true

class TradeHub < ApplicationRecord
  has_many :trade_commodities,
           dependent: :nullify
  has_many :commodities,
           through: :trade_commodities

  validates :name, :station_type, :planet, :system, presence: true
  validates :name, uniqueness: true

  before_save :update_slugs

  accepts_nested_attributes_for :trade_commodities, allow_destroy: true

  enum station_type: %i[hub truckstop mining-station asteroid-station outpost]

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
