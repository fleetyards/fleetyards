# frozen_string_literal: true

require "test_helper"

class ModuleHardpointTest < ActiveSupport::TestCase
  # A module's cached fragments are keyed on the module, and it embeds the ships
  # it is linked to -- so unlinking one has to move the module too.
  test "unlinking a ship moves the module's updated_at" do
    link = create(:module_hardpoint)
    model_module = link.model_module
    model_module.update_columns(updated_at: 1.day.ago)

    link.destroy!

    assert_operator model_module.reload.updated_at, :>, 1.minute.ago
  end

  test "fill_missing_slots places a module linked before its hull had a slot" do
    model = create(:model)
    unplaced = create(:module_hardpoint, model:, slot: nil)
    placed = create(:module_hardpoint, model:, slot: "hardpoint_kept")
    stock = create(:component, sc_key: "rsi_module_base", category: "module", component_type: "Module")
    create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_module", category: :module, component: stock)

    ModuleHardpoint.fill_missing_slots(model)

    assert_equal "hardpoint_module", unplaced.reload.slot
    assert_equal "hardpoint_kept", placed.reload.slot
  end

  test "fill_missing_slots leaves a module unplaced while the hull has no slot for it" do
    model = create(:model)
    unplaced = create(:module_hardpoint, model:, slot: nil)

    ModuleHardpoint.fill_missing_slots(model)

    assert_nil unplaced.reload.slot
  end
end
