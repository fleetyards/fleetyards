# frozen_string_literal: true

class ShipRole < ApplicationRecord
  include SlugHelper

  has_many :ships

  before_save :update_slugs

  validates :name, presence: true

  private def update_slugs
    self.slug = SlugHelper.generate_slug name
  end
end
