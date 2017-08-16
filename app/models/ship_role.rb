# frozen_string_literal: true

class ShipRole < ApplicationRecord
  include SlugHelper

  has_many :ships

  before_save :update_slugs

  validates :name, presence: true

  def self.with_name
    where.not(name: nil)
  end

  def self.with_ship
    includes(:ships).where.not(ships: { ship_role_id: nil })
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug name
  end
end
