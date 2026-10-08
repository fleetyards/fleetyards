# frozen_string_literal: true

class InventoryPosition < ApplicationRecord
  include StockPosition

  inventory_association :inventory

  has_many :inventory_items, dependent: :restrict_with_error
end
