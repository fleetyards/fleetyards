# frozen_string_literal: true
require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ShipsLoader.new }

  test "#run" do
    assert_difference lambda {
      Hardpoint.count + Component.count + ComponentCategory.count +
        Ship.count + Manufacturer.count + ShipRole.count
    }, +1132 do
      loader.run
    end
  end
end
