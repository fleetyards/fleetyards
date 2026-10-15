# frozen_string_literal: true

class VehicleLoadoutItem < ApplicationRecord
  # What a slot can hold. Components join once their categories are fitted.
  ITEM_TYPES = %w[ModelModule].freeze

  # Written through `VehicleLoadout#item_list=`, which checks the fitting as a
  # whole: one item per slot path, owned by the vehicle, in a slot it fits.
  belongs_to :vehicle_loadout, touch: true
  belongs_to :item, polymorphic: true

  validates :item_type, inclusion: {in: ITEM_TYPES}
end
