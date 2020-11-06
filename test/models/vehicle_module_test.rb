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
require 'test_helper'

class VehicleModuleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
