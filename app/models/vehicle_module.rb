# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_modules
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_module_id :uuid
#  vehicle_id      :uuid
#
class VehicleModule < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :model_module
end
