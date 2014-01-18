class ShipRole < ActiveRecord::Base
  include SlugHelper

  has_many :ships

  before_create :set_defaults
  before_save :update_slugs

  private def set_defaults
    self.name = self.rsi_name
    self.slug = SlugHelper::generate_slug self.name
  end

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
