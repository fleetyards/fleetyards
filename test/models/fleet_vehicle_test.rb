# frozen_string_literal: true

require "test_helper"

class FleetVehicleTest < ActiveSupport::TestCase
  should belong_to(:vehicle)
  should belong_to(:fleet)
end
