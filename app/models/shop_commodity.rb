# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  paginates_per 30

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

  has_many :trade_routes, dependent: :destroy

  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item
  after_save :update_model_price

  attr_accessor :commodity_item_selected

  ransack_alias :name, :model_name_or_component_name_or_commodity_item_of_Commodity_type_name_or_equipment_name_or_model_module_name
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
end
