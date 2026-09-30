# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsDefensesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/defenses" do
    get("Ship defenses for the penetration check") do
      operationId "modelDefenses"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::ModelDefensesList
      end
    end
  end

  ARMOR_DATA = {
    "health" => 3840.0,
    "damage_physical" => 0.75,
    "damage_energy" => 0.6,
    "damage_distortion" => 1.0,
    "damage_thermal" => 1.0,
    "deflection_physical" => 11.0,
    "deflection_energy" => 9.0,
    "deflection_distortion" => 0.0,
    "deflection_thermal" => 0.0
  }.freeze

  SHIELD_DATA = {
    "max_health" => 2160.0,
    "max_regen" => 410.0,
    "absorption" => {"physical" => {"min" => 0.0, "max" => 0.45}, "energy" => {"min" => 1.0, "max" => 1.0}},
    "resistance" => {"physical" => {"min" => 0.0, "max" => 0.25}}
  }.freeze

  setup do
    @model = create(:model, name: "Gladius")
    armor = create(:component, category: "armor", type_data: ARMOR_DATA)
    shield = create(:component, category: "shieldgenerator", type_data: SHIELD_DATA)

    create(:hardpoint, parent: @model, source: :game_files, component: armor)
    create(:hardpoint, parent: @model, source: :game_files, component: shield)
    create(:hardpoint, parent: @model, source: :game_files, component: create(:component, category: "cooler"))
  end

  test "GET /models/defenses lists armor and shields per ship" do
    assert_api_response :get, 200 do
      entry = parsed_body.sole

      assert_equal "Gladius", entry["name"]
      assert_equal 3840.0, entry.dig("armor", "health")
      assert_equal 0.75, entry.dig("armor", "damagePhysical")
      assert_equal 11.0, entry.dig("armor", "deflectionPhysical")

      shield = entry["shields"].sole
      assert_equal 2160.0, shield["maxHealth"]
      assert_equal 0.45, shield.dig("absorption", "physical", "max")
      assert_equal 0.25, shield.dig("resistance", "physical", "max")
    end
  end

  test "GET /models/defenses resolves a shield nested under another slot" do
    parent = @model.hardpoints.find_by!(category: :cooler)
    create(:hardpoint, parent:, source: :game_files,
      component: create(:component, category: "shieldgenerator", type_data: SHIELD_DATA))

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.sole["shields"].count
    end
  end

  test "GET /models/defenses reads the slot's build, not its column" do
    retired = create(:component, category: "shieldgenerator", type_data: SHIELD_DATA)
    create(:hardpoint, :without_build, parent: @model, source: :game_files, component: retired)

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.sole["shields"].count
    end
  end

  test "GET /models/defenses leaves out ships without armor or shields" do
    create(:model, name: "Unarmoured")

    assert_api_response :get, 200 do
      assert_equal ["Gladius"], parsed_body.map { |entry| entry["name"] }
    end
  end

  test "GET /models/defenses leaves out hidden ships" do
    @model.update!(hidden: true)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /models/defenses leaves out a size the ship does not have" do
    @model.update_column(:size, nil)

    assert_api_response :get, 200 do
      assert_not parsed_body.sole.key?("size")
    end
  end
end
