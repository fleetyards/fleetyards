# frozen_string_literal: true

# == Schema Information
#
# Table name: celestial_objects
#
#  id                :uuid             not null, primary key
#  code              :string
#  description       :text
#  designation       :string
#  fairchanceact     :boolean
#  habitable         :boolean
#  hidden            :boolean          default(TRUE)
#  last_updated_at   :datetime
#  name              :string
#  object_type       :string
#  orbit_period      :string
#  sensor_danger     :integer
#  sensor_economy    :integer
#  sensor_population :integer
#  size              :string
#  slug              :string
#  status            :string
#  store_image       :string
#  sub_type          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :uuid
#  rsi_id            :integer
#  starsystem_id     :uuid
#
# Indexes
#
#  index_celestial_objects_on_starsystem_id  (starsystem_id)
#
class CelestialObject < ApplicationRecord
  paginates_per 30

  searchkick index_prefix: -> { },
             searchable: %i[name starsystem parent designation],
             word_start: %i[name]

  def search_data
    {
      name: name,
      starsystem: starsystem&.slug,
      parent: parent&.slug,
      designation: designation,
      main: parent.blank?,
      visible: !hidden
    }
  end

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

  def location_label
    I18n.t('activerecord.attributes.celestial_object.location_prefix.default', starsystem: starsystem.name)
  end
end
