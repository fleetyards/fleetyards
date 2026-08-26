# frozen_string_literal: true

require "test_helper"

# Resolution on its own: what a loadout says should exist, without a single row
# being written. That is the point of splitting it out of `update_loadout` --
# the rules used to be reachable only by running the writes, so every assertion
# about them had to go through hardpoint rows and the cleanup that follows.
module ScData
  module Loader
    class BaseLoaderResolutionTest < ActiveSupport::TestCase
      setup do
        @loader = ::ScData::Loader::BaseLoader.new
        @model = create(:model, sc_key: "drak_caterpillar")
      end

      private def resolve(loadout, model: nil)
        @loader.send(:resolve_loadout, loadout, model:)
      end

      test "resolving writes nothing" do
        create(:component, sc_key: "power_plant_s2")

        assert_no_difference("Hardpoint.count") do
          resolve({"loadout" => [{"name" => "hardpoint_power", "key" => "power_plant_s2"}]})
        end
      end

      test "names the slot by the lowered hardpoint name and resolves its component" do
        component = create(:component, sc_key: "power_plant_s2")

        slots = resolve({"loadout" => [{"name" => "Hardpoint_POWER", "key" => "Power_Plant_S2"}]})

        assert_equal ["hardpoint_power"], slots.map(&:name)
        assert_equal [component], slots.map(&:component)
      end

      test "leaves the component nil when nothing resolves" do
        slots = resolve({"loadout" => [{"name" => "hardpoint_mystery", "key" => "absent"}]})

        assert_nil slots.sole.component
      end

      test "carries a nested loadout as the slot's children" do
        create(:component, sc_key: "turret_s4")
        gun = create(:component, sc_key: "gun_s2")

        slots = resolve({
          "loadout" => [{
            "name" => "hardpoint_turret",
            "key" => "turret_s4",
            "loadout" => [{"name" => "hardpoint_gun", "key" => "gun_s2"}]
          }]
        })

        assert_equal [gun], slots.sole.children.map(&:component)
      end

      test "omits a blacklisted entry entirely" do
        slots = resolve({"loadout" => [
          {"name" => "hardpoint_fuelpod_2_console"},
          {"name" => "aegs_retaliator_door_cap_rear"}
        ]})

        assert_empty slots
      end

      # The hidden component contributes its sub-hardpoints as siblings at this
      # level, plus the retain-only slot that keeps an existing row of its own
      # name from being cleaned up.
      test "flattens a hidden component into sibling slots" do
        cargo_grid = create(:component, sc_key: "cargo_grid_s4")
        door = create(:component, :hidden, sc_key: "cargo_door")
        create(:hardpoint, parent: door, sc_name: "grid", component: cargo_grid, source: :game_files)

        slots = resolve({"loadout" => [{"name" => "hardpoint_door", "key" => "cargo_door"}]})

        assert_equal ["hardpoint_door-grid", "hardpoint_door"], slots.map(&:name)
        assert_equal [cargo_grid, nil], slots.map(&:component)
        assert_equal [nil, true], slots.map(&:retain_only)
      end

      # Derived only for a ship. A module's own loadout, and every nested level,
      # resolves without it -- which is why the model is passed rather than read
      # off whatever happens to be the parent.
      test "derives the module key only when given a model" do
        component = create(:component, sc_key: "drak_caterpillar_module")

        with_model = resolve({"loadout" => [{"name" => "cargo_module"}]}, model: @model)
        without_model = resolve({"loadout" => [{"name" => "cargo_module"}]})

        assert_equal component, with_model.sole.component
        assert_nil without_model.sole.component
      end

      test "adopts a default without altering the loadout it was handed" do
        create(:component, sc_key: "default_gun")
        loadout = {
          "loadout" => [{"name" => "hardpoint_gun"}],
          "default_loadout" => [{"name" => "hardpoint_gun", "key" => "default_gun"}]
        }

        resolve(loadout)

        assert_nil loadout["loadout"].sole["key"], "the parsed hash belongs to the caller"
      end
    end
  end
end
