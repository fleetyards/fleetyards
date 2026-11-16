# frozen_string_literal: true

require "test_helper"

class ComponentHardpointTransformsTest < ActiveSupport::TestCase
  test "touches the modules the part is, whose holds it places" do
    model_module = create(:model_module, sc_key: "RSI_Galaxy_Module_Cargo")
    other = create(:model_module, sc_key: "RSI_Galaxy_Module_Medical")
    part = create(:component, sc_key: "rsi_galaxy_module_cargo", category: "module", component_type: "Module")

    travel 1.minute do
      part.update!(hardpoint_transforms: {"cargo_grids" => []})
    end

    assert_operator model_module.reload.updated_at, :>, other.reload.updated_at
  end

  test "leaves the modules alone when only the doors change" do
    model_module = create(:model_module, sc_key: "RSI_Galaxy_Module_Cargo")
    part = create(:component, sc_key: "rsi_galaxy_module_cargo", category: "module", component_type: "Module")
    part.update!(hardpoint_transforms: {"cargo_grids" => []})
    before = model_module.reload.updated_at

    travel 1.minute do
      part.hardpoint_transforms_record.update!(doors: [{"id" => "door"}])
    end

    assert_equal before, model_module.reload.updated_at
  end
end
