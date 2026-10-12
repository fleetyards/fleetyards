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
  end

  # Once keyed, a module is only offered for a build it has a row for, and other
  # modules already hold rows -- so without one the beds vanish until a load.
  test "a mapped module gets a row for the build each environment serves, and stays offered" do
    live = ScData::Source.find("live")
    create(:model_module_build, environment: "live", version: "4.0.0-live.1")
    create(:model_module_build, environment: "live", version: live.version)
    bed = module_on(ship("Apollo Medivac"), "Tier 1 Module Left")

    MapApolloModulesToGameFiles.new.up

    assert_equal [["live", live.version]], bed.builds.pluck(:environment, :version)
    assert_nil bed.builds.sole.description
    assert_includes ModelModule.in_build(live.served_for(ModelModuleBuild)), bed
  end

  # An environment with no module builds offers every module; a row there would
  # hide all the others.
  test "an environment with no module builds gets no row" do
    bed = module_on(ship("Apollo Triage"), "Tier 2 Module Right")
    other = create(:model_module, sc_key: "Something_Else")

    MapApolloModulesToGameFiles.new.up

    assert_empty bed.builds
    assert_includes ModelModule.in_build(ScData::Source.find("live")), other
  end

  test "a bed an admin had already keyed gets its row too" do
    create(:model_module_build, environment: "live", version: ScData::Source.find("live").version)
    keyed = module_on(ship("Apollo Medivac"), "Tier 3 Module Left", sc_key: "RSI_Apollo_Module_Left_Tier_3")

    MapApolloModulesToGameFiles.new.up

    assert_equal 1, keyed.builds.count
  end
end
