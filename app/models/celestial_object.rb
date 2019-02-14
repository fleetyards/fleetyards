# frozen_string_literal: true

class CelestialObject < ApplicationRecord
  paginates_per 30

  belongs_to :starsystem, optional: true

  belongs_to :parent,
             class_name: 'CelestialObject',
             optional: true

  has_many :moons,
           class_name: 'CelestialObject',
           foreign_key: :parent_id,
           inverse_of: :parent,
           dependent: :destroy

  has_many :affiliations,
           as: :affiliationable,
           dependent: :destroy
  has_many :factions, through: :affiliations

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  ransack_alias :starsystem, :starsystem_slug

  def self.main
    where(parent_id: nil)
  end

  def self.planet
    where(object_type: 'PLANET')
  end

  def self.moon
    where(object_type: 'SATELLITE')
  end

  def self.visible
    where(hidden: false)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
