# frozen_string_literal: true

class VehicleModule < ApplicationRecord
  belongs_to :vehicle
  belongs_to :model_module
end
