# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261012140000_map_apollo_modules_to_game_files.rb")

class MapApolloModulesToGameFilesTest < ActiveSupport::TestCase
  def ship(name)
    create(:model, name:)
  end

  def module_on(model, name, sc_key: nil, **attributes)
    create(:model_module, name:, sc_key:, **attributes).tap do |model_module|
      create(:module_hardpoint, model:, model_module:)
    end
  end

  test "each Apollo bed module gets the item record the game files ship it as" do
    triage = ship("Apollo Triage")
    left = module_on(triage, "Tier 2 Module Left")
    right = module_on(triage, "Tier 3 Module Right")

    MapApolloModulesToGameFiles.new.up

    assert_equal "RSI_Apollo_Module_Left_Tier_2", left.reload.sc_key
    assert_equal "RSI_Apollo_Module_Right_Tier_3", right.reload.sc_key
  end

  test "a module of the same name on another ship is left alone" do
    other = module_on(ship("Carrack"), "Tier 1 Module Left")

    MapApolloModulesToGameFiles.new.up

    assert_nil other.reload.sc_key
  end

  test "a key an admin already set is kept" do
    mapped = module_on(ship("Apollo Medivac"), "Tier 1 Module Right", sc_key: "Something_Else")

    MapApolloModulesToGameFiles.new.up

    assert_equal "Something_Else", mapped.reload.sc_key
    assert_empty mapped.builds
  end

  # Once keyed, a module is only offered for a build it has a row for, and other
  # modules already hold rows -- so without these the beds vanish until a load.
  test "a mapped module gets a row for every build the table holds, and stays offered" do
    create(:model_module_build, environment: "live", version: "4.3.0-live.1")
    create(:model_module_build, environment: "ptu", version: "4.4.0-ptu.2")
    bed = module_on(ship("Apollo Medivac"), "Tier 1 Module Left", description: "Two beds.")

    MapApolloModulesToGameFiles.new.up

    assert_equal [["live", "4.3.0-live.1"], ["ptu", "4.4.0-ptu.2"]],
      bed.builds.order(:environment).pluck(:environment, :version)
    assert_equal ["Two beds."], bed.builds.distinct.pluck(:description)

    live = ScData::Source.new(environment: "live", version: "4.3.0-live.1")

    assert_includes ModelModule.in_build(live), bed
  end
end
