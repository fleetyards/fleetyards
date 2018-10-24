# frozen_string_literal: true

class Starsystem < ApplicationRecord
  has_many :celestial_objects,
           dependent: :destroy
  has_many :planets,
           -> { CelestialObject.planet },
           inverse_of: :starsystem,
           class_name: 'CelestialObject'
  has_many :moons,
           -> { CelestialObject.moon },
           inverse_of: :starsystem,
           class_name: 'CelestialObject'

  has_many :affiliations,
           as: :affiliationable,
           dependent: :destroy
  has_many :factions, through: :affiliations

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
