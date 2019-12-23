# frozen_string_literal: true

class Station < ApplicationRecord
  paginates_per 10

  searchkick searchable: %i[name station_type celestial_object starsystem],
             word_start: %i[name],
             filterable: []

  def search_data
    {
      name: name,
      station_type: station_type,
      celestial_object: celestial_object.name,
      starsystem: celestial_object.starsystem&.name
    }
  end

  def should_index?
    !hidden
  end

  has_many :shops, dependent: :destroy
  has_many :docks,
           -> { order(ship_size: :asc) },
           dependent: :destroy,
           inverse_of: :station
  has_many :habitations,
           -> { order(habitation_type: :desc) },
           dependent: :destroy,
           inverse_of: :station

  has_many :images,
           as: :gallery,
           dependent: :destroy,
           inverse_of: :gallery

  belongs_to :celestial_object

  enum station_type: { spaceport: 0, hub: 1, rest_stop: 2, station: 3, "cargo-station": 4, "mining-station": 5, "mining-hub": 13, "asteroid-station": 6, refinery: 7, district: 8, outpost: 9, aid_shelter: 10, gate: 11, drug_lab: 12 }
  ransacker :station_type, formatter: proc { |v| Station.station_types[v] } do |parent|
    parent.table[:station_type]
  end
  ransack_alias :habs, :habitations_station_id
  ransack_alias :starsystem, :celestial_object_starsystem_slug
  ransack_alias :celestial_object, :celestial_object_slug
  ransack_alias :name, :name_or_slug
  ransack_alias :search, :name_or_slug_or_celestial_object_starsystem_slug_or_celestial_object_slug

  validates :name, :station_type, :celestial_object, presence: true
  validates :name, uniqueness: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :map, ImageUploader

  accepts_nested_attributes_for :docks, allow_destroy: true

  delegate :starsystem, to: :celestial_object

  def self.visible
    where(hidden: false)
  end

  def self.type_filters
    Station.station_types.map do |(item, _index)|
      Filter.new(
        category: 'station_type',
        name: Station.human_enum_name(:station_type, item),
        value: item
      )
    end
  end

  def location_label
    "#{location_prefix} #{celestial_object.name}"
  end

  def location_prefix
    case station_type
    when 'asteroid-station'
      I18n.t('activerecord.attributes.station.location_prefix.asteriod')
    when 'hub', 'rest_stop', 'station', 'cargo-station', 'mining-station'
      I18n.t('activerecord.attributes.station.location_prefix.orbit')
    else
      I18n.t('activerecord.attributes.station.location_prefix.default')
    end
  end

  def image
    images.first
  end

  def random_image
    images.enabled.background.order(Arel.sql('RANDOM()')).first
  end

  def habitation_counts
    habitations.group_by(&:habitation_type).map do |habitation_type, habitations_by_type|
      OpenStruct.new(habitation_type: habitation_type, habitation_type_label: habitations_by_type.first.habitation_type_label, count: habitations_by_type.size)
    end.flatten
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        OpenStruct.new(size: size, dock_type: dock_type, dock_type_label: docks_by_type.first.dock_type_label, count: docks_by_type.size)
      end
    end.flatten
  end

  def shop_list_label
    shops.map(&:name).join(', ')
  end

  def station_type_label
    Station.human_enum_name(:station_type, station_type)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
