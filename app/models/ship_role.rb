class ShipRole < ActiveRecord::Base
  translates :name

  include SlugHelper

  has_many :ships

  before_save :update_slugs

  validates_presence_of :name

  private def update_slugs
    self.slug = SlugHelper::generate_slug self.name
  end
end
