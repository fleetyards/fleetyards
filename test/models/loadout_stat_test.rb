# frozen_string_literal: true

require "test_helper"

class LoadoutStatTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, production_status: "flight-ready")
    @vehicle = create(:vehicle, model: @model)

    @gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "3")
    @small_gun = create(:component, component_type: "WeaponGun", category: "weapons", size: "2")
    @gimbal = create(:component, component_type: "Turret", category: "weapon_mounts", size: "3")
    port(@gimbal, "hardpoint_class_2", types: ["WeaponGun"], min_size: 2, max_size: 3)

    %w[hardpoint_gun_left hardpoint_gun_right].each do |name|
      mount = port(@model, name, types: %w[Turret WeaponGun], min_size: 3, max_size: 3, component: @gimbal)
      port(mount, "hardpoint_class_2", min_size: 3, max_size: 3, component: @gun)
    end

    @source = ::ScData::Source.current.served
  end

  def port(parent, name, **attributes)
    create(:hardpoint, parent:, sc_name: name, source: :game_files, **attributes)
  end

  def fit(*pairs, public: false)
    items = pairs.map do |slot, component|
      component ? {slot_path: slot, item_type: "Component", item_id: component.id} : {slot_path: slot, item_type: "Empty"}
    end
    create(:vehicle_loadout, :fleetyards, :active, vehicle: @vehicle, public:, item_list: items)
  end

  def stat_of(fitting)
    LoadoutStat.find_by!(fitting:, environment: @source.environment)
  end

  def assert_fitted(expected, public_only: false)
    vehicle = Vehicle.includes(Vehicle.rendered_associations).find(@vehicle.id)

    assert_equal expected, vehicle.fitted_weapons(public_only:)&.max_weapon_size.to_i
    assert_equal expected, Vehicle.where(id: @vehicle.id).pick(Arel.sql(Vehicle.fitted_max_weapon_size_sql(public_only:)))
  end

  test "counts the guns a ship comes with by size, through their mounts" do
    LoadoutStat.refresh(@source)

    stat = stat_of(@model)
    assert_equal({"3" => 2}, stat.weapon_sizes)
    assert_equal 3, stat.max_weapon_size
    assert_equal @source.version, stat.version
  end

  test "leaves out a mining laser filed as a gun" do
    laser = create(:component, component_type: "WeaponGun", category: "weapons", size: "4",
      type_data: {mining: {power_transfer: 1800}})
    port(@model, "hardpoint_mining_laser", types: ["WeaponGun"], min_size: 4, max_size: 4, component: laser)

    LoadoutStat.refresh(@source)

    assert_equal({"3" => 2}, stat_of(@model).weapon_sizes)
  end

  test "a loadout counts the guns it fits and the stock ones it leaves in" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])

    LoadoutStat.refresh(@source)

    assert_equal({"3" => 1, "2" => 1}, stat_of(loadout).weapon_sizes)
  end

  test "a gun the loadout takes out is not counted" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", nil], ["hardpoint_gun_right/hardpoint_class_2", nil])

    LoadoutStat.refresh(@source)

    assert_equal({}, stat_of(loadout).weapon_sizes)
    assert_nil stat_of(loadout).max_weapon_size
  end

  test "saving a fleetyards loadout queues its refresh, and a linked one does not" do
    assert_difference -> { LoadoutStatsJob.jobs.size }, 1 do
      fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])
    end

    assert_no_difference -> { LoadoutStatsJob.jobs.size } do
      create(:vehicle_loadout, vehicle: @vehicle)
    end
  end

  test "switching, renaming or showing a loadout queues nothing, as its guns stay the same" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])
    other = fit(["hardpoint_gun_right/hardpoint_class_2", @small_gun])

    assert_no_difference -> { LoadoutStatsJob.jobs.size } do
      loadout.activate!
      loadout.update!(name: "Renamed", public: true)
    end

    assert_difference -> { LoadoutStatsJob.jobs.size }, 1 do
      other.update!(item_list: [])
    end
  end

  test "a vehicle moved to another ship queues its loadouts' refresh" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])
    LoadoutStatsJob.jobs.clear

    @vehicle.update!(model: create(:model, production_status: "flight-ready"))

    assert_equal [{"vehicle_loadout_id" => loadout.id}], LoadoutStatsJob.jobs.map { |job| job["args"].first }
  end

  test "a reloaded ship refreshes its stock guns and its loadouts" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])

    LoadoutStatsJob.new.perform("model_id" => @model.id)

    assert_equal 3, stat_of(@model).max_weapon_size
    assert_equal({"3" => 1, "2" => 1}, stat_of(loadout).weapon_sizes)
  end

  test "counts the guns of the modules a ship comes with" do
    turret = create(:model_module, sc_key: "TEST_Turret_Module")
    create(:module_hardpoint, model: @model, model_module: turret, slot: "hardpoint_module")
    port(@model, "hardpoint_module", category: :module,
      component: create(:component, category: :module, component_type: "Module", sc_key: "test_turret_module"))
    port(turret, "hardpoint_module_gun", types: ["WeaponGun"], min_size: 5, max_size: 5,
      component: create(:component, component_type: "WeaponGun", category: "weapons", size: "5"))

    LoadoutStat.refresh(@source)

    assert_equal({"5" => 1, "3" => 2}, stat_of(@model).weapon_sizes)
  end

  test "a vehicle left with two active loadouts still reads its guns" do
    first = fit(["hardpoint_gun_left/hardpoint_class_2", nil], ["hardpoint_gun_right/hardpoint_class_2", nil])
    fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])
    VehicleLoadout.where(id: first.id).update_all(active: true)
    LoadoutStat.refresh(@source)

    assert_equal 3, Vehicle.where(id: @vehicle.id).pick(Arel.sql(Vehicle.fitted_max_weapon_size_sql))
  end

  test "the queued refresh writes the loadout's stats" do
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", @small_gun])

    LoadoutStatsJob.new.perform("vehicle_loadout_id" => loadout.id)

    assert_equal 3, stat_of(loadout).max_weapon_size
  end

  test "a vehicle without a loadout carries the guns the ship comes with" do
    LoadoutStat.refresh(@source)

    assert_fitted 3
  end

  test "an active loadout decides, even when it carries no guns at all" do
    fit(["hardpoint_gun_left/hardpoint_class_2", nil], ["hardpoint_gun_right/hardpoint_class_2", nil])
    LoadoutStat.refresh(@source)

    assert_fitted 0
  end

  test "a private loadout counts only for its owner" do
    fit(["hardpoint_gun_left/hardpoint_class_2", nil], ["hardpoint_gun_right/hardpoint_class_2", nil])
    LoadoutStat.refresh(@source)

    assert_fitted 0
    assert_fitted 3, public_only: true
  end

  test "a loadout whose stats are not written yet falls back to the ship's" do
    LoadoutStat.refresh(@source)
    loadout = fit(["hardpoint_gun_left/hardpoint_class_2", nil])
    loadout.loadout_stats.delete_all

    assert_fitted 3
  end

  test "stats of another environment are not read" do
    LoadoutStat.refresh(@source)
    LoadoutStat.where(fitting: @model).update_all(environment: "elsewhere")

    assert_fitted 0
  end
end
