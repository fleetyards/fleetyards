# frozen_string_literal: true

require "test_helper"

class HardpointOrePodTest < ActiveSupport::TestCase
  private def hardpoint(sc_name, sc_key: nil)
    component = sc_key && create(:component, component_type: "Container", category: "utility", sc_key:)
    create(:hardpoint, source: :game_files, sc_name:, component:)
  end

  test "files a mining pod slot under ore pods" do
    pod = hardpoint("hardpoint_mining_pod_1", sc_key: "cargo_shipmining_pod_prospector")

    assert pod.ore_pod_group?
    assert pod.ore_pods_category?
  end

  test "files an empty mining pod slot under ore pods" do
    pod = hardpoint("hardpoint_mining_pod_1")

    assert pod.ore_pod_group?
    assert pod.ore_pods_category?
  end

  test "files an ore pod fitted to another slot under ore pods" do
    pod = hardpoint("hardpoint_cargogrid_main", sc_key: "cargo_groundvehiclemining_pod_roc")

    assert pod.ore_pod_group?
    assert pod.ore_pods_category?
  end

  test "leaves a stowed, collapsed pod where it was" do
    stowed = hardpoint("hardpoint_stored_pod_1", sc_key: "cargo_shipmining_pod_mole_collapsed")

    assert stowed.auxiliary_group?
    assert stowed.utility_category?
  end

  test "leaves a cargo pod that holds no ore where it was" do
    pod = hardpoint("hardpoint_cargo_pod", sc_key: "cargo_pod_raft_temp")

    assert pod.auxiliary_group?
    assert pod.utility_category?
  end
end
