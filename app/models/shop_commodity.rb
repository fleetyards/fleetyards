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
end
