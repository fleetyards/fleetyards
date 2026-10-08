# frozen_string_literal: true

# One material a slot accepts. Every slot in 4.10.1 accepts exactly one, but the
# game files allow several and the UI already has the string for it.
class BlueprintCostOption < ApplicationRecord
  belongs_to :slot,
    class_name: "BlueprintCostSlot", inverse_of: :options,
    foreign_key: :blueprint_cost_slot_id

  # Nullable: a material the commodity catalogue has no row for must not take
  # the recipe down with it, and `commodity_key` still says which one it is.
  belongs_to :commodity, optional: true

  # Also the unit. A resource is measured in SCU, an item in whole pieces.
  TYPES = %w[resource item].freeze

  validates :cost_type, presence: true, inclusion: {in: TYPES}
  validates :position, presence: true, uniqueness: {scope: :blueprint_cost_slot_id}
end
