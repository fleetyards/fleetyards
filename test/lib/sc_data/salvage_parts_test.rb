# frozen_string_literal: true

require "test_helper"

module ScData
  class SalvagePartsTest < ActiveSupport::TestCase
    def item(key, type, type_data = nil)
      {"key" => key, "ref" => "#{key}-ref", "type" => type, "type_data" => type_data}
    end

    def slot(name, item, loadout = [])
      {"name" => name, "key" => nil, "ref" => item["ref"], "loadout" => loadout}
    end

    test "hands each Moth station its own cab's crates, and the tool arm the hull work" do
      crates = ->(size) { {"salvage_controller" => true, "heads" => 1, "crates" => {"max_size" => size, "fill_time_per_scu" => 3.0}} }
      items = [
        front = item("controller_salvage_argo_moth_frontcab", "SalvageController", crates.call(1)),
        left = item("controller_salvage_argo_moth_left", "SalvageController", crates.call(8)),
        right = item("controller_salvage_argo_moth_right", "SalvageController", crates.call(8)),
        arm_controller = item("controller_salvage_argo_moth_toolarm", "SalvageController",
          {"salvage_controller" => true, "heads" => 0, "crates" => {"max_size" => 1},
           "disintegration" => {"max_radius" => 60.75, "time_per_metre" => 2.52},
           "field_alignment" => {"max_yield_multiplier" => 1.5}}),
        station_left = item("salvagefillerstation_argo_moth_left", "SalvageFillerStation"),
        station_right = item("salvagefillerstation_argo_moth_right", "SalvageFillerStation"),
        arm = item("argo_moth_salvage_arm", "ToolArm"),
        intake = item("salvagedisintegrationarea", "SalvageFieldEmitter"),
        mining_arm = item("misc_mining_arm", "ToolArm")
      ]
      moth = {"loadout" => [
        slot("hardpoint_controller_mining_cab_front", front),
        slot("hardpoint_controller_mining_cab_left", left),
        slot("hardpoint_controller_mining_cab_right", right),
        slot("hardpoint_controller_salvage_tool_arm", arm_controller),
        slot("hardpoint_salvage_filler_left", station_left),
        slot("hardpoint_salvage_filler_right", station_right),
        slot("hardpoint_tool_arm", arm, [slot("disintegration_intake", intake)]),
        slot("hardpoint_mining_arm", mining_arm)
      ]}

      facts = SalvageParts.new([moth], items_by_key: items.index_by { |entry| entry["key"] }, items_by_ref: items.index_by { |entry| entry["ref"] }).facts

      assert_equal 8, facts.dig("salvagefillerstation_argo_moth_left", "salvage", "crates", "max_size")
      assert_equal 8, facts.dig("salvagefillerstation_argo_moth_right", "salvage", "crates", "max_size")
      assert_in_delta 60.75, facts.dig("argo_moth_salvage_arm", "salvage", "disintegration", "max_radius")
      assert_nil facts.dig("argo_moth_salvage_arm", "salvage", "crates")
      assert_nil facts["salvagedisintegrationarea"], "the intake is shared by every salvage ship"
      assert_nil facts["misc_mining_arm"]
    end
  end
end
