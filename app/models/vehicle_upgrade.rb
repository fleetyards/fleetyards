# frozen_string_literal: true

class VehicleUpgrade < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :model_upgrade
end
