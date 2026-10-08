# frozen_string_literal: true

class InventoryItem < ApplicationRecord
  include InventoryLedgerEntry

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  inventory_association :inventory
  position_association :inventory_position

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality inventory_id created_at updated_at position_id inventory_position_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inventory item]
  end
end
