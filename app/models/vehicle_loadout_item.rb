# frozen_string_literal: true

class VehicleLoadoutItem < ApplicationRecord
  # Written through `VehicleLoadout#item_list=`, which checks the fitting as a
  # whole: one item per slot, owned by the vehicle, in a slot the module fits.
  belongs_to :vehicle_loadout, touch: true
  belongs_to :model_module
end
