# frozen_string_literal: true

class Station < ApplicationRecord
  has_many :station_shops,
           dependent: :destroy
  has_many :shops,
           through: :station_shops
  has_many :docks,
           dependent: :destroy

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  belongs_to :planet, required: false

  enum station_type: %i[hub truckstop refinary cargo-station mining-station asteroid-station outpost]

  validates :name, :station_type, presence: true
  validates :name, uniqueness: true

  before_save :update_slugs

  accepts_nested_attributes_for :docks, allow_destroy: true

  delegate :starsystem, to: :planet

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
