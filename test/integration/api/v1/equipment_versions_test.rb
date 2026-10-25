# frozen_string_literal: true

require "openapi_helper"

class Api::V1::EquipmentVersionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/equipment/{slug}/versions" do
    parameter name: :slug, in: :path, schema: {type: :string}, required: true

    get("Other versions of an equipment item") do
      operationId "equipmentItemVersions"
      tags "Equipment"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/EquipmentList"
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @rifle = create(:equipment, name: "Gallant Rifle", sc_key: "klwe_rifle_energy_01", family_key: "klwe_rifle_energy_01")
    create(:equipment, name: "Gallant \"Boneyard\" Rifle", sc_key: "klwe_rifle_energy_01_white02",
      family_key: "klwe_rifle_energy_01")
    create(:equipment, name: "Gallant \"Boneyard\" Rifle", sc_key: "klwe_rifle_energy_01_white02_tow",
      family_key: "klwe_rifle_energy_01", hidden: true)
    create(:equipment, name: "Arrowhead Sniper Rifle", sc_key: "klwe_sniper_energy_01")
  end

  test "GET /equipment/{slug}/versions lists the visible rest of the family" do
    assert_api_response :get, 200, path_params: {slug: @rifle.slug} do
      assert_equal ["Gallant \"Boneyard\" Rifle"], parsed_body.pluck("name")
    end
  end

  test "GET /equipment/{slug}/versions is empty for an item without a family" do
    sniper = Equipment.find_by(sc_key: "klwe_sniper_energy_01")

    assert_api_response :get, 200, path_params: {slug: sniper.slug} do
      assert_empty parsed_body
    end
  end

  test "GET /equipment/{slug}/versions returns 404 for an unknown item" do
    assert_api_response :get, 404, path_params: {slug: "nope-nope"}
  end
end
