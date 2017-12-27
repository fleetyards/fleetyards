# frozen_string_literal: true

class Commodity < ApplicationRecord
  has_many :trade_commodities,
           dependent: :nullify
  has_many :trade_hubs,
           through: :trade_commodities

  validates :name, presence: true

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
