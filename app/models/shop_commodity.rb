# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  paginates_per 15

  belongs_to :commodity_item, polymorphic: true, required: false
  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item

  attr_accessor :commodity_item_selected

  ransack_alias :name, :commodity_item_of_Model_type_name_or_commodity_item_of_Component_type_name_or_commodity_item_of_Commodity_type_name_or_commodity_item_of_Equipment_type_name_or_commodity_item_of_ModelModule_type_name
  ransack_alias :category, :commodity_item_type
  ransack_alias :sub_category, :commodity_item_of_Model_type_classification_or_commodity_item_of_Component_type_component_class_or_commodity_item_of_Equipment_type_equipment_type
  ransack_alias :manufacturer, :commodity_item_of_Model_type_manufacturer_slug_or_commodity_item_of_Component_type_manufacturer_slug_or_commodity_item_of_Equipment_type_manufacturer_slug_or_commodity_item_of_ModelModule_type_manufacturer_slug
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
