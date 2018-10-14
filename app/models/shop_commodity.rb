# frozen_string_literal: true

class ShopCommodity < ApplicationRecord
  belongs_to :commodity_item, polymorphic: true, required: false
  belongs_to :shop

  validate :name_or_commodity_item

  before_validation :set_commodity_item

  attr_accessor :commodity_item_selected

  def name_or_commodity_item
    return if name.present? ^ commodity_item.present?

    errors.add(:name, 'Name or Commodity item needs to be present')
    errors.add(:commodity_item, 'Name or Commodity item needs to be present')
  end

  def set_commodity_item
    self.commodity_item = if commodity_item_selected.blank?
                            nil
                          else
                            GlobalID::Locator.locate(commodity_item_selected)
                          end
  end
end
