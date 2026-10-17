# frozen_string_literal: true

class VehicleLoadoutItem < ApplicationRecord
  # A component slot left out of a loadout keeps the part it came with, so
  # taking that part out is an item of its own: the slot, and nothing in it.
  EMPTY = "Empty"

  # What a slot can hold.
  ITEM_TYPES = ["ModelModule", "Component", EMPTY].freeze

  # Written through `VehicleLoadout#item_list=`, which checks the fitting as a
  # whole: one item per slot path, each in a slot it fits.
  belongs_to :vehicle_loadout, touch: true
  belongs_to :item, polymorphic: true, optional: true

  validates :item_type, inclusion: {in: ITEM_TYPES}
  validates :item_id, presence: true, unless: :empty?
  validates :item_id, absence: true, if: :empty?

  def empty?
    item_type == EMPTY
  end
end
