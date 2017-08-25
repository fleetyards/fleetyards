# frozen_string_literal: true

require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ShipsLoader.new }

  test "#all" do
    VCR.use_cassette("ships_loader_all") do
      loader.all

      expectations = {
        hardpoints: 2086,
        components: 216,
        component_categories: 4,
        ships: 104,
        manufacturers: 15,
        ship_roles: 64
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

  test "#updates only when needed" do
    VCR.use_cassette("ships_loader_all") do
      Timecop.freeze(Time.zone.now) do
        loader.one('Origin 600i Explorer')

        ship = Ship.find_by(name: 'Origin 600i Explorer')

        Timecop.travel(1.day)

        loader.one(ship.name)
        ship.reload

        assert(ship.updated_at.day != Time.zone.now.day)
      end
    end
  end
end
