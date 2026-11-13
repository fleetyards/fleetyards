# frozen_string_literal: true

require "test_helper"

class HangarModuleMappingTest < ActiveSupport::TestCase
  include HangarModuleMapping

  test "a module name shared between ships keeps each ship's game-data key" do
    galaxy = component_mapping("Galaxy – Cargo Module")
    aurora = component_mapping("Aurora Mk II Cargo Module")

    assert_equal "Cargo Module", galaxy[:module_name]
    assert_equal "Cargo Module", aurora[:module_name]
    assert_equal "RSI_Galaxy_Module_Cargo", galaxy[:sc_key]
    assert_equal "RSI_Aurora_Mk2_Module_Cargo", aurora[:sc_key]
  end

  test "the Galaxy refinery module stays unlinked until the game ships it" do
    assert_nil component_mapping("Galaxy - Refinery Module")[:sc_key]
  end
end
