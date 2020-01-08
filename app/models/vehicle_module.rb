# frozen_string_literal: true

class VehicleModule < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :model_module
end
