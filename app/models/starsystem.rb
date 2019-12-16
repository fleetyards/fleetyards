# frozen_string_literal: true

class Starsystem < ApplicationRecord
  paginates_per 15

  searchkick searchable: %i[name],
             word_start: %i[name],
             filterable: []

  def search_data
    {
      name: name,
    }
  end

  def should_index?
    !hidden
  end

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

  ransack_alias :name, :name_or_slug
  ransack_alias :search, :name_or_slug

  def self.visible
    where(hidden: false)
  end

  def location_label
    factions.first&.name
  end
end
