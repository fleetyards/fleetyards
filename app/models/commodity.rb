# frozen_string_literal: true

class Commodity < ApplicationRecord
  paginates_per 50

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  enum commodity_type: %i[gas metal mineral non_metals agricultural_supply food medical_supply processed_goods waste scrap vice]

  ransacker :commodity_type, formatter: proc { |v| Commodity.commodity_types[v] } do |parent|
    parent.table[:commodity_type]
  end

  ransack_alias :type, :commodity_type

  validates :name, presence: true, uniqueness: true
  ransack_alias :name, :name_or_slug

  before_save :update_slugs

  mount_uploader :store_image, CommodityStoreImageUploader

  def self.type_filters
    Commodity.commodity_types.map do |(item, _index)|
      Filter.new(
        category: 'commodity_type',
        name: Commodity.human_enum_name(:commodity_type, item),
        value: item
      )
    end
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  def commodity_type_label
    Commodity.human_enum_name(:commodity_type, commodity_type)
  end
end
