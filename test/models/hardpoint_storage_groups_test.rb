# frozen_string_literal: true

require "test_helper"

class HardpointStorageGroupsTest < ActiveSupport::TestCase
  private def hardpoint(component_type, category)
    component = create(:component, component_type:, category:)
    create(:hardpoint, source: :game_files, sc_name: "hardpoint_#{category}", component:)
  end

  test "keeps a cargo grid in the other group" do
    assert hardpoint("CargoGrid", "cargogrid").other_group?
  end

  test "files a module under modules" do
    assert hardpoint("Module", "module").module_group?
  end

  test "files a salvage filler station under salvage storage" do
    assert hardpoint("SalvageFillerStation", "salvagefillerstation").salvage_storage_group?
  end

  test "files salvage storage under salvage storage" do
    storage = hardpoint("SalvageInternalStorage", "salvagemunching")

    assert storage.salvage_storage_group?
    assert storage.salvage_storage_category?
  end
end
