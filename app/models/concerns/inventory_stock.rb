# frozen_string_literal: true

module InventoryStock
  extend ActiveSupport::Concern

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  included do
    before_save :update_slugs
  end

  class_methods do
    def inventory_items_association(association_name)
      has_many association_name, dependent: :destroy

      alias_method :inventory_items, association_name
    end
  end

  def ledger_attributes_for(_user)
    {}
  end

  def current_stock
    inventory_items
      .select(
        "name, category, unit, quality",
        "SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) AS net_quantity"
      )
      .group(:name, :category, :unit, :quality)
      .having("SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) > 0")
      .order(:name)
  end
end
