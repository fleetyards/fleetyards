# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261012140000_map_apollo_modules_to_game_files.rb")

class MapApolloModulesToGameFilesTest < ActiveSupport::TestCase
  def ship(slug)
    create(:model).tap { |model| model.update_column(:slug, slug) }
  end

  def module_on(model, name, sc_key: nil)
    create(:model_module, name:, sc_key:).tap do |model_module|
      create(:module_hardpoint, model:, model_module:)
    end
  end

  test "each Apollo bed module gets the item record the game files ship it as" do
    apollo = ship("rsi-apollo-triage")
    left = module_on(apollo, "Tier 2 Module Left")
    right = module_on(apollo, "Tier 3 Module Right")

    MapApolloModulesToGameFiles.new.up

    assert_equal "RSI_Apollo_Module_Left_Tier_2", left.reload.sc_key
    assert_equal "RSI_Apollo_Module_Right_Tier_3", right.reload.sc_key
  end

  test "a module of the same name on another ship is left alone" do
    other = module_on(ship("anvl-carrack"), "Tier 1 Module Left")

    MapApolloModulesToGameFiles.new.up

    assert_nil other.reload.sc_key
  end

  test "a key an admin already set is kept" do
    mapped = module_on(ship("rsi-apollo-medivac"), "Tier 1 Module Right", sc_key: "Something_Else")

    MapApolloModulesToGameFiles.new.up

    assert_equal "Something_Else", mapped.reload.sc_key
  end
end
