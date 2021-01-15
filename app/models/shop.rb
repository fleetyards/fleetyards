# frozen_string_literal: true

# == Schema Information
#
# Table name: shops
#
#  id                :uuid             not null, primary key
#  buying            :boolean          default(FALSE)
#  description       :text
#  hidden            :boolean          default(TRUE)
#  location          :string
#  name              :string
#  refinery_terminal :boolean
#  rental            :boolean          default(FALSE)
#  selling           :boolean          default(FALSE)
#  shop_type         :integer
#  slug              :string
#  store_image       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  station_id        :uuid
#
# Indexes
#
#  index_shops_on_station_id  (station_id)
#
class Shop < ApplicationRecord
  paginates_per 30

  searchkick searchable: %i[name shop_type station celestial_object starsystem refinery],
             word_start: %i[name],
             filterable: []

  def search_data
    {
      name: name,
      shop_type: shop_type,
      station: station.name,
      celestial_object: station.celestial_object.name,
      starsystem: station.celestial_object.starsystem&.name,
      refinery: refinery_terminal? ? 'Refinery' : ''
    }
  end

  def should_index?
    !hidden
  end

  belongs_to :station, touch: true
  has_many :shop_commodities, dependent: :destroy

  validates :name, :station, :shop_type, presence: true

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :shop_commodities, allow_destroy: true

  enum shop_type: {
    clothing: 0, armor: 1, weapons: 2, components: 3, armor_and_weapons: 4, superstore: 5,
    ships: 6, admin: 7, bar: 8, hospital: 9, salvage: 10, resources: 11, rental: 12,
    computers: 13, blackmarket: 14, mining_equipment: 15, equipment: 16, courier: 17, refinery: 18
  }
  ransacker :shop_type, formatter: proc { |v| Shop.shop_types[v] } do |parent|
    parent.table[:shop_type]
  end

  ransack_alias :name, :name_or_slug
  ransack_alias :model, :shop_commodities_commodity_item_of_Model_type_slug
  ransack_alias :component, :shop_commodities_commodity_item_of_Component_type_slug
  ransack_alias :commodity, :shop_commodities_commodity_item_of_Commodity_type_slug
  ransack_alias :equipment, :shop_commodities_commodity_item_of_Equipment_type_slug
  ransack_alias :commodity_category, :shop_commodities_commodity_item_type
  ransack_alias :station, :station_slug
  ransack_alias :celestial_object, :station_celestial_object_slug
  ransack_alias :starsystem, :station_celestial_object_starsystem_slug

  before_validation :update_shop_commodities
  before_save :update_slugs

  def self.visible
    where(hidden: false)
  end

  def self.type_filters
    Shop.shop_types.map do |(item, _index)|
      Filter.new(
        category: 'shop_type',
        name: Shop.human_enum_name(:shop_type, item),
        value: item
      )
    end
  end

  def shop_type_label
    Shop.human_enum_name(:shop_type, shop_type)
  end

  def station_label
    [
      I18n.t('activerecord.attributes.shop.location_prefix.default'),
      station.name,
    ].join(' ')
  end

  def location_label
    [
      I18n.t('activerecord.attributes.shop.location_prefix.default'),
      station.name,
      location,
      station.location_label
    ].compact.join(' ')
  end

  private def update_shop_commodities
    shop_commodities.each(&:set_commodity_item)
  end
end
