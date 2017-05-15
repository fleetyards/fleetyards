# frozen_string_literal: true

require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ShipsLoader.new }

  test "#all" do
    VCR.use_cassette("ships_loader_all") do
      loader.all
      expectations = {
        hardpoints: 0,
        components: 1845,
        component_categories: 4,
        ships: 91,
        manufacturers: 14,
        ship_roles: 88
      }
      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   component_categories: ComponentCategory.count,
                   ships: Ship.count,
                   manufacturers: Manufacturer.count,
                   ship_roles: ShipRole.count)
    end
  end
end
