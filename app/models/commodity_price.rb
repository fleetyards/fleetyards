# frozen_string_literal: true

class CommodityPrice < ApplicationRecord
  belongs_to :shop_commodity

  validates :price, presence: true
end
