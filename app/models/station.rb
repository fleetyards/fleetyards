# frozen_string_literal: true

# == Schema Information
#
# Table name: stations
#
#  id                  :uuid             not null, primary key
#  cargo_hub           :boolean
#  classification      :integer
#  description         :text
#  habitable           :boolean          default(TRUE)
#  hidden              :boolean          default(TRUE)
#  images_count        :integer          default(0)
#  location            :string
#  map                 :string
#  name                :string
#  refinery            :boolean
#  slug                :string
#  station_type        :integer
#  status              :integer
#  store_image         :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  celestial_object_id :uuid
#  planet_id           :uuid
#
# Indexes
#
#  index_stations_on_celestial_object_id  (celestial_object_id)
#  index_stations_on_name                 (name) UNIQUE
#  index_stations_on_planet_id            (planet_id)
#
class Station < ApplicationRecord
  paginates_per 10

  searchkick searchable: %i[name station_type classification celestial_object starsystem refinery cargo_hub],
             word_start: %i[name]

  def search_data
    {
      name: name,
      station_type: station_type,
      classification: classification,
      celestial_object: celestial_object.name,
      starsystem: celestial_object.starsystem&.name,
      cargo_hub: cargo_hub? ? 'Cargo Hub' : '',
      refinery: refinery? ? 'Refinery' : ''
    }
  end

  def should_index?
    !hidden
  end

  belongs_to :celestial_object

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

  enum station_type: {
    landing_zone: 0, station: 1, asteroid_station: 2, district: 3, outpost: 4, aid_shelter: 5
  }

  enum classification: {
    city: 0, trading: 1, mining: 2, salvaging: 3, farming: 4, science: 5, security: 6,
    rest_stop: 7, settlement: 8, town: 9, drug_lab: 10
  }

  ransacker :station_type, formatter: proc { |v| Station.station_types[v] } do |parent|
    parent.table[:station_type]
  end
  ransacker :classification, formatter: proc { |v| Station.classifications[v] } do |parent|
    parent.table[:classification]
  end
  ransack_alias :habs, :habitations_station_id
  ransack_alias :starsystem, :celestial_object_starsystem_slug
  ransack_alias :celestial_object, :celestial_object_slug
  ransack_alias :name, :name_or_slug
  ransack_alias :search, :name_or_slug_or_celestial_object_starsystem_slug_or_celestial_object_slug

  validates :name, :station_type, presence: true
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

  def self.classification_filters
    Station.classifications.map do |(item, _index)|
      Filter.new(
        category: 'classification',
        name: Station.human_enum_name(:classification, item),
        value: item
      )
    end
  end

  def self.with_shops(filters)
    scope = includes(:shops).where.not(shops: { station_id: nil })

    if filters[:commodity_item_type].present?
      shop_type = Shop.shop_type_for_commodity_type(filters[:commodity_item_type])

      scope = scope.where(shops: { shop_type: shop_type }) if shop_type.present?
    end

    scope
  end

  def location_label
    if location.present?
      "#{location_prefix} #{location}"
    else
      "#{location_prefix} #{celestial_object.name}"
    end
  end

  def location_prefix
    if location.present?
      I18n.t('activerecord.attributes.station.location_prefix.near')
    elsif asteroid_station?
      I18n.t('activerecord.attributes.station.location_prefix.asteriod')
    elsif station?
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
      HabitationCount.new(habitation_type: habitation_type, habitation_type_label: habitations_by_type.first.habitation_type_label, habitation_count: habitations_by_type.size)
    end.flatten
  end

  def dock_counts
    docks.to_a.group_by(&:ship_size).map do |size, docks_by_size|
      docks_by_size.group_by(&:dock_type).map do |dock_type, docks_by_type|
        DockCount.new(dock_size: size, dock_type: dock_type, dock_type_label: docks_by_type.first.dock_type_label, dock_count: docks_by_type.size)
      end
    end.flatten
  end

  def shop_list_label
    shops.map(&:name).join(', ')
  end

  def station_type_label
    Station.human_enum_name(:station_type, station_type)
  end

  def classification_label
    Station.human_enum_name(:classification, classification)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
