# frozen_string_literal: true

class Shop < ApplicationRecord
  paginates_per 20

  belongs_to :station
  has_many :shop_commodities, dependent: :destroy

  validates :name, :station, :shop_type, presence: true

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :shop_commodities, allow_destroy: true

  enum shop_type: %i[clothing armor weapons components armor_and_weapons superstore ships admin bar hospital salvage resources rental]
  ransacker :shop_type, formatter: proc { |v| Shop.shop_types[v] } do |parent|
    parent.table[:shop_type]
  end

  ransack_alias :name, :name_or_slug
  ransack_alias :commodity_name, :shop_commodities_commodity_item_of_Model_type_name_or_shop_commodities_commodity_item_of_Component_type_name_or_shop_commodities_commodity_item_of_Commodity_type_name_or_shop_commodities_commodity_item_of_Equipment_type_name
  ransack_alias :commodity_category, :shop_commodities_commodity_item_type
  ransack_alias :station, :station_slug
  ransack_alias :celestial_object, :station_celestial_object_slug
  ransack_alias :starsystem, :station_celestial_object_starsystem_slug

  before_save :update_slugs
  before_validation :update_shop_commodities

  def shop_type_label
    Shop.human_enum_name(:shop_type, shop_type)
  end

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

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end

  private def update_shop_commodities
    shop_commodities.each(&:set_commodity_item)
  end
end
