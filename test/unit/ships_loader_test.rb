# frozen_string_literal: true

require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ShipsLoader.new }

  test "#all" do
    VCR.use_cassette("ships_loader_all") do
      assert_difference lambda {
        Hardpoint.count + Component.count + ComponentCategory.count +
          Ship.count + Manufacturer.count + ShipRole.count
      }, +2042 do
        loader.all
      end
    end
  end
end
