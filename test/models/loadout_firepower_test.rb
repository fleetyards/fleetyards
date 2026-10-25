# frozen_string_literal: true

require "test_helper"

# The same fixtures `useLoadoutStats.fixtures.spec.ts` reads: real ships'
# hardpoint trees as the hardpoints endpoint renders them, and the firepower
# the browser works out for them. The server has to land on the same figures.
class LoadoutFirepowerTest < ActiveSupport::TestCase
  FIXTURES = Rails.root.glob("test/fixtures/loadout_stats/*.json").sort

  test "there are fixtures to check" do
    assert_not_empty FIXTURES
  end

  FIXTURES.each do |path|
    test "agrees with the browser on #{path.basename(".json")}" do
      fixture = JSON.parse(path.read).deep_transform_keys(&:underscore)
      expected = fixture.fetch("expected")

      result = LoadoutFirepower.new(
        fixture["hardpoints"],
        weapon_pool_size: fixture["weapon_pool_size"],
        regen_modifier: fixture["regen_modifier"]
      ).call

      assert_in_delta expected["alpha"], result.alpha, 1e-6
      assert_in_delta expected["burst_dps"], result.burst_dps, 1e-6
      assert_in_delta expected["sustained_dps_min"], result.sustained_dps_min, 1e-6
      assert_in_delta expected["sustained_dps_max"], result.sustained_dps_max, 1e-6
    end
  end
end
