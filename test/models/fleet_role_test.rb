# frozen_string_literal: true

require "test_helper"

class FleetRoleTest < ActiveSupport::TestCase
  should belong_to(:fleet)
end
