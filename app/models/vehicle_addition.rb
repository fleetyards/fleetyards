# frozen_string_literal: true

class VehicleAddition < ApplicationRecord
  belongs_to :ship, required: true
end
