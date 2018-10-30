# frozen_string_literal: true

require 'test_helper'

class CelestialObjectTest < ActiveSupport::TestCase
  should belong_to(:starsystem)
  should belong_to(:parent)

  should validate_presence_of(:name)
  should validate_presence_of(:name)

  let(:stanton) { starsystems :stanton }
  let(:hurston) { celestial_objects :hurston }
  let(:uriel) { celestial_objects :uriel }
end
