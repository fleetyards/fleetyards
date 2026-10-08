# frozen_string_literal: true

class FleetInventoryPosition < ApplicationRecord
  include StockPosition

  inventory_association :fleet_inventory

  has_many :fleet_inventory_items, dependent: :restrict_with_error
end
