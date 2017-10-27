# frozen_string_literal: true

require 'test_helper'
require 'ships_loader'

class ShipsLoaderTest < ActiveSupport::TestCase
  let(:loader) { ShipsLoader.new }

  test "#all" do
    VCR.use_cassette('ships_loader_all', record: :new_episodes) do
      loader.all

      expectations = {
        hardpoints: 0,
        components: 0,
        component_categories: 0,
        ships: 108,
        manufacturers: 16
      }

      assert_equal(expectations,
                   hardpoints: Hardpoint.count,
                   components: Component.count,
                   component_categories: ComponentCategory.count,
                   ships: Ship.count,
                   manufacturers: Manufacturer.count)
    end
  end

  test "#updates only when needed" do
    VCR.use_cassette('ships_loader_all', record: :new_episodes) do
      Timecop.freeze(Time.zone.now) do
        loader.one('600i Explorer')

        ship = Ship.find_by(name: '600i Explorer')

        Timecop.travel(1.day)

        loader.one(ship.name)
        ship.reload

        assert(ship.updated_at.day != Time.zone.now.day)
        assert_equal(91.5, ship.length.to_f)
      end
    end
  end
end
