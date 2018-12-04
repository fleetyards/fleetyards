# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  paginates_per 15

  belongs_to :commodity_item, polymorphic: true, required: false
  belongs_to :model,
             -> { where(shop_commodities: { commodity_item_type: 'Model' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities
  def model
    return unless commodity_item_type == 'Model'

    super
  end

  belongs_to :component,
             -> { where(shop_commodities: { commodity_item_type: 'Component' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities
  def component
    return unless commodity_item_type == 'Component'

    super
  end

  belongs_to :commodity,
             -> { where(shop_commodities: { commodity_item_type: 'Commodity' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities
  def commodity
    return unless commodity_item_type == 'Commodity'

    super
  end

  belongs_to :equipment,
             -> { where(shop_commodities: { commodity_item_type: 'Equipment' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities
  def equipment
    return unless commodity_item_type == 'Equipment'

    super
  end

  belongs_to :model_module,
             -> { where(shop_commodities: { commodity_item_type: 'ModelModule' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities
  def model_module
    return unless commodity_item_type == 'ModelModule'

    super
  end

  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item

  attr_accessor :commodity_item_selected

  ransack_alias :name, :model_name_or_component_name_or_commodity_item_of_Commodity_type_name_or_equipment_name_or_model_module_name
  ransack_alias :category, :commodity_item_type
  ransack_alias :sub_category, :model_classification_or_component_component_class_or_equipment_equipment_type
  ransack_alias :manufacturer, :model_manufacturer_slug_or_component_manufacturer_slug_or_equipment_manufacturer_slug_or_model_module_manufacturer_slug
  ransack_alias :price, :sell_price_or_buy_price_or_rent_price

  def set_commodity_item
    return if commodity_item_selected.blank?

    self.commodity_item = GlobalID::Locator.locate(commodity_item_selected)
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
    end
  end
end
