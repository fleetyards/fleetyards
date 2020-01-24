# frozen_string_literal: true

require 'test_helper'

class CelestialObjectTest < ActiveSupport::TestCase
  should belong_to(:starsystem).optional(true)
  should belong_to(:parent).optional(true)
end
