# frozen_string_literal: true

require "test_helper"

class VehicleFittedCargoTest < ActiveSupport::TestCase
  setup do
    @model = create(:model, production_status: "flight-ready", cargo: 2, keep_cargo: true)
    @front_cargo = create(:model_module, cargo: 38, sc_key: "RETA_Front_Cargo")
    @front_torpedo = create(:model_module, sc_key: "RETA_Front_Torpedo")
    @rear_cargo = create(:model_module, cargo: 36, sc_key: "RETA_Rear_Cargo")
    create(:module_hardpoint, model: @model, model_module: @front_cargo, slot: "hardpoint_front_module")
    create(:module_hardpoint, model: @model, model_module: @front_torpedo, slot: "hardpoint_front_module")
    create(:module_hardpoint, model: @model, model_module: @rear_cargo, slot: "hardpoint_rear_module")

    @vehicle = create(:vehicle, model: @model)
  end

  def comes_with(slot, model_module)
    create(:hardpoint, parent: @model, category: :module, source: :game_files, sc_name: slot,
      component: create(:component, category: :module, component_type: "Module", sc_key: model_module.sc_key.downcase))
  end

  def fit(items, public: false)
    create(:vehicle_loadout, :fleetyards, :active, vehicle: @vehicle, public:, item_list: items)
  end

  def module_in(slot, model_module)
    {slot_path: slot, item_type: "ModelModule", item_id: model_module.id}
  end

  def assert_fitted_cargo(expected, public_only: false)
    vehicle = Vehicle.includes(Vehicle.rendered_associations).find(@vehicle.id)

    assert_in_delta expected, vehicle.fitted_cargo(public_only:)
    assert_in_delta expected, Vehicle.where(id: @vehicle.id).pick(Arel.sql(Vehicle.fitted_cargo_sql(public_only:))).to_f
  end

  test "a vehicle without a loadout carries its hull and offers the modules on top" do
    assert_fitted_cargo 2

    assert_in_delta 76, @vehicle.reload.cargo_with_modules
  end

  test "a vehicle without a loadout carries the cargo modules it comes with" do
    comes_with("hardpoint_front_module", @front_cargo)

    assert_fitted_cargo 40
    assert_in_delta 76, @vehicle.reload.cargo_with_modules
  end

  test "a vehicle whose stock modules already carry the most offers nothing more" do
    comes_with("hardpoint_front_module", @front_cargo)
    comes_with("hardpoint_rear_module", @rear_cargo)

    assert_fitted_cargo 76
    assert_nil @vehicle.reload.cargo_with_modules
  end

  test "an active loadout carries the cargo modules it fits and says how the ship is fitted" do
    fit([module_in("hardpoint_rear_module", @rear_cargo)])

    assert_fitted_cargo 38
    assert_nil @vehicle.reload.cargo_with_modules
  end

  test "a loadout carries only the modules it fits, not the stock ones it leaves out" do
    comes_with("hardpoint_front_module", @front_cargo)
    comes_with("hardpoint_rear_module", @rear_cargo)
    fit([module_in("hardpoint_rear_module", @rear_cargo)])

    assert_fitted_cargo 38
  end

  test "a loadout kept on another site counts as no loadout" do
    create(:vehicle_loadout, :active, vehicle: @vehicle)

    assert_fitted_cargo 2
    assert_in_delta 76, @vehicle.reload.cargo_with_modules
  end

  test "a private loadout counts only for its owner" do
    fit([module_in("hardpoint_rear_module", @rear_cargo)])

    assert_fitted_cargo 38
    assert_fitted_cargo 2, public_only: true
    assert_in_delta 76, @vehicle.reload.cargo_with_modules(public_only: true)
  end

  test "a public loadout counts for everybody" do
    fit([module_in("hardpoint_rear_module", @rear_cargo)], public: true)

    assert_fitted_cargo 38, public_only: true
  end

  test "a concept ship carries the most it can" do
    @model.update!(production_status: "in-concept")

    assert_fitted_cargo 76
    assert_nil @vehicle.reload.cargo_with_modules
  end
end
