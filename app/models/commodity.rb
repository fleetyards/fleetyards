# frozen_string_literal: true

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :integer
#  description    :text
#  name           :string
#  slug           :string
#  store_image    :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_commodities_on_name  (name) UNIQUE
#
class Commodity < ApplicationRecord
  paginates_per 50

  searchkick searchable: %i[name commodity_type],
    word_start: %i[name commodity_type]

  def search_data
    {
      name:,
      commodity_type:
    }
  end

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  enum commodity_type: {gas: 0, metal: 1, mineral: 2, non_metals: 3, agricultural_supply: 4, food: 5, medical_supply: 6, processed_goods: 7, waste: 8, scrap: 9, vice: 10, harvestable: 11, consumer_goods: 12}

  ransacker :commodity_type, formatter: proc { |v| Commodity.commodity_types[v] } do |parent|
    parent.table[:commodity_type]
  end

  ransack_alias :type, :commodity_type

  def self.ransackable_attributes(auth_object = nil)
    [
      "commodity_type", "created_at", "description", "id", "id_value", "name", "slug",
      "store_image", "type", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shop_commodities"]
  end

  validates :name, presence: true, uniqueness: true
  ransack_alias :name, :name_or_slug

  before_save :update_slugs

  mount_uploader :store_image, CommodityStoreImageUploader

  def self.type_filters
    Commodity.commodity_types.map do |(item, _index)|
      Filter.new(
        category: "commodity_type",
        label: Commodity.human_enum_name(:commodity_type, item),
        value: item
      )
    end
  end

  def self.ordered_by_name
    order(name: :asc)
  end

  def sold_at
    shop_commodities.where.not(sell_price: nil).order(sell_price: :asc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).order(buy_price: :desc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def listed_at
    shop_commodities.where(sell_price: nil, buy_price: nil).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def commodity_type_label
    Commodity.human_enum_name(:commodity_type, commodity_type)
  end
end
