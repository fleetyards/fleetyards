# frozen_string_literal: true

class VehicleUpgrade < ApplicationRecord
  belongs_to :vehicle
  belongs_to :model_upgrade
end
