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
             word_start: %i[name commodity_type],
             filterable: []

  def search_data
    {
      name: name,
      commodity_type: commodity_type
    }
  end

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  enum commodity_type: { gas: 0, metal: 1, mineral: 2, non_metals: 3, agricultural_supply: 4, food: 5, medical_supply: 6, processed_goods: 7, waste: 8, scrap: 9, vice: 10, harvestable: 11 }

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

  def sold_at
    shop_commodities.where.not(sell_price: nil).uniq { |item| item.shop.slug }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).uniq { |item| item.shop.slug }
  end

  def commodity_type_label
    Commodity.human_enum_name(:commodity_type, commodity_type)
  end
end
