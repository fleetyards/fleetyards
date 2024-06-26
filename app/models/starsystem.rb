# frozen_string_literal: true

# == Schema Information
#
# Table name: starsystems
#
#  id                    :uuid             not null, primary key
#  aggregated_danger     :integer
#  aggregated_economy    :integer
#  aggregated_population :integer
#  aggregated_size       :string
#  code                  :string
#  description           :text
#  hidden                :boolean          default(TRUE)
#  last_updated_at       :datetime
#  map                   :string
#  map_x                 :string
#  map_y                 :string
#  name                  :string
#  position_x            :string
#  position_y            :string
#  position_z            :string
#  slug                  :string
#  status                :string
#  store_image           :string
#  system_type           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  rsi_id                :integer
#
class Starsystem < ApplicationRecord
  paginates_per 15

  searchkick searchable: %i[name],
    word_start: %i[name]

  def search_data
    {
      name:
    }
  end

  def should_index?
    !hidden
  end

  has_many :celestial_objects,
    dependent: :destroy
  has_many :planets,
    -> { CelestialObject.planet },
    dependent: :destroy,
    inverse_of: :starsystem,
    class_name: "CelestialObject"
  has_many :moons,
    -> { CelestialObject.moon },
    dependent: :destroy,
    inverse_of: :starsystem,
    class_name: "CelestialObject"

  has_many :affiliations,
    as: :affiliationable,
    dependent: :destroy
  has_many :factions, through: :affiliations

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  ransack_alias :name, :name_or_slug
  ransack_alias :search, :name_or_slug

  def self.ransackable_attributes(auth_object = nil)
    [
      "aggregated_danger", "aggregated_economy", "aggregated_population", "aggregated_size", "code",
      "created_at", "description", "hidden", "id", "id_value", "last_updated_at", "map", "map_x",
      "map_y", "name", "position_x", "position_y", "position_z", "rsi_id", "search", "slug",
      "status", "store_image", "system_type", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["affiliations", "celestial_objects", "factions", "moons", "planets"]
  end

  def self.visible
    where(hidden: false)
  end

  def location_label
    factions.first&.name
  end
end
