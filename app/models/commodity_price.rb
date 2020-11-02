# frozen_string_literal: true

class CommodityPrice < ApplicationRecord
  belongs_to :shop_commodity, touch: true

  validates :price, presence: true
end
