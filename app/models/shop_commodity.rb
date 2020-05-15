# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  paginates_per 30

  searchkick searchable: %i[name manufacturer_name manufacturer_code shop station celestial_object starsystem],
             word_start: %i[name manufacturer_name],
             filterable: []

  def search_data
    {
      name: commodity_item.name,
      manufacturer_name: commodity_item.manufacturer&.name,
      manufacturer_code: commodity_item.manufacturer&.code,
      shop: shop.name,
      station: shop.station.name,
      celestial_object: shop.station.celestial_object.name,
      starsystem: shop.station.celestial_object.starsystem&.name
    }
  end

  def should_index?
    commodity_item.is_a?(Equipment) || commodity_item.is_a?(Component)
  end

  belongs_to :commodity_item, polymorphic: true, optional: true
  belongs_to :model,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Model' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :component,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Component' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :commodity,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Commodity' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :equipment,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Equipment' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :model_module,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'ModelModule' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  has_many :trade_route_origins,
           class_name: 'TradeRoute',
           dependent: :destroy,
           foreign_key: 'origin_id',
           inverse_of: :origin

  has_many :trade_route_destinations,
           class_name: 'TradeRoute',
           dependent: :destroy,
           foreign_key: 'destination_id',
           inverse_of: :destination

  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item
  after_save :update_model_price

  attr_accessor :commodity_item_selected

  ransack_alias :name, :model_name_or_component_name_or_commodity_name_or_equipment_name_or_model_module_name
  ransack_alias :category, :commodity_item_type
  ransack_alias :sub_category, :model_classification_or_component_component_class_or_equipment_equipment_type
  ransack_alias :manufacturer, :model_manufacturer_slug_or_component_manufacturer_slug_or_equipment_manufacturer_slug_or_model_module_manufacturer_slug
  ransack_alias :price, :sell_price_or_buy_price_or_rent_price

  def self.commodity
    where(commodity_item_type: ['Commodity'])
  end

  def self.visible
    includes(:shop).where(shops: { hidden: false })
  end

  def set_commodity_item
    return if commodity_item_selected.blank?

    self.commodity_item = GlobalID::Locator.locate(commodity_item_selected)
  end

  def update_model_price
    return if model.blank?

    model.update(price: ShopCommodity.where(commodity_item_id: model.id, commodity_item_type: 'Model').order(sell_price: :desc).first&.sell_price)
  end

  def category
    commodity_item.class.name.underscore
  end

  def sub_category
    case commodity_item_type
    when 'Model'
      commodity_item.classification
    when 'Component'
      commodity_item.component_class
    when 'Equipment'
      commodity_item.equipment_type
    when 'Commodity'
      commodity_item.commodity_type
    end
  end

  def sub_category_label
    case commodity_item_type
    when 'Model'
      commodity_item.classification&.humanize
    when 'Component'
      commodity_item.component_class_label
    when 'Equipment'
      commodity_item.equipment_type_label
    when 'Commodity'
      commodity_item.commodity_type_label
    end
  end

  def location_label
    [
      I18n.t('activerecord.attributes.shop_commodity.location_prefix.default'),
      shop.name,
      I18n.t('activerecord.attributes.station.location_prefix.default'),
      shop.station.name
    ].join(' ')
  end
end
