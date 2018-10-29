# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  paginates_per 30

  belongs_to :commodity_item, polymorphic: true, required: false
  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item

  attr_accessor :commodity_item_selected

  def set_commodity_item
    return if commodity_item_selected.blank?

    self.commodity_item = GlobalID::Locator.locate(commodity_item_selected)
  end

  def category
    commodity_item.class.name.downcase
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

  def manufacturer
    return unless %w[Model Equipment Component].include?(commodity_item_type)

    commodity_item.manufacturer
  end
end
