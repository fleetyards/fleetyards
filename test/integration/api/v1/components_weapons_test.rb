# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ComponentsWeaponsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/components/weapons" do
    get("Ship guns for the deflection check") do
      operationId "componentWeapons"
      tags "Components"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::WeaponIndex
      end
    end
  end

  setup do
    @version = ScData::Source.version

    @gun = create(
      :component,
      name: "Test Gatling",
      category: "weapons",
      component_sub_type: "Gun",
      version: @version,
      type_data: {"damage_per_shot" => {"physical" => 19.0, "energy" => 0.0}}
    )
  end

  test "GET /components/weapons lists current-version guns" do
    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
      assert_equal "Test Gatling", parsed_body.first["name"]
      assert_equal 19.0, parsed_body.first["damagePerShot"]["physical"]
      # Types absent from the parsed data still serialize, so the frontend can
      # read every damage type without null checks.
      assert_equal 0.0, parsed_body.first["damagePerShot"]["thermal"]
    end
  end

  test "GET /components/weapons excludes other categories and sub types" do
    create(:component, category: "weapons", component_sub_type: "Missile",
      version: @version, type_data: {"damage_per_shot" => {"physical" => 500.0}})
    create(:component, category: "coolers", component_sub_type: "Gun",
      version: @version, type_data: {"damage_per_shot" => {"physical" => 1.0}})

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
    end
  end

  test "GET /components/weapons excludes older game versions" do
    create(:component, category: "weapons", component_sub_type: "Gun",
      version: "0.0.1-live.1", type_data: {"damage_per_shot" => {"physical" => 5.0}})

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
    end
  end

  test "GET /components/weapons excludes game-file-only variants" do
    %w[
      behr_lasercannon_s9_lowpoly behr_lasercannon_s6_turret
      anvl_ballisticgatling_bespoke apar_ballisticscattergun_s1_shark
    ].each do |key|
      create(:component, category: "weapons", component_sub_type: "Gun",
        sc_key: key, version: @version,
        type_data: {"damage_per_shot" => {"physical" => 100.0}})
    end

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
      assert_equal "Test Gatling", parsed_body.first["name"]
    end
  end

  test "GET /components/weapons exposes pellet count and beam flag" do
    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.first["pelletsPerShot"]
      assert_equal false, parsed_body.first["beam"]
    end
  end

  test "GET /components/weapons skips guns with no parsed data" do
    create(:component, category: "weapons", component_sub_type: "Gun",
      version: @version, type_data: nil)

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body.count
    end
  end
end
