# frozen_string_literal: true

require "openapi_helper"

class Api::V1::EquipmentWeaponsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/equipment/{slug}/weapons" do
    parameter name: :slug, in: :path, schema: {type: :string}, required: true

    get("Weapons an attachment fits") do
      operationId "equipmentItemWeapons"
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
    @suppressor = create(:equipment, name: "Tacit Suppressor2", sc_key: "arma_barrel_supp_s2",
      equipment_type: "weapon_attachment", sub_type: "Barrel")

    rifle = create(:equipment, name: "Gallant Rifle", sc_key: "klwe_rifle_energy_01", family_key: "klwe_rifle_energy_01")
    skin = create(:equipment, name: "Gallant \"Boneyard\" Rifle", sc_key: "klwe_rifle_energy_01_white02",
      family_key: "klwe_rifle_energy_01")
    sniper = create(:equipment, name: "Arrowhead Sniper Rifle", sc_key: "klwe_sniper_energy_01")
    older = create(:equipment, name: "Retired Rifle", sc_key: "klwe_rifle_energy_09", version: "0.0.1-live.1")

    [rifle, skin, sniper, older].each do |weapon|
      create(:equipment_attachment, build: weapon.builds.sole, attachment: @suppressor, port_name: "barrel_attach",
        port_type: "Barrel")
    end
  end

  test "GET /equipment/{slug}/weapons lists one weapon per family in the build we are on" do
    assert_api_response :get, 200, path_params: {slug: @suppressor.slug} do
      assert_equal ["Arrowhead Sniper Rifle", "Gallant Rifle"], parsed_body.pluck("name")
    end
  end

  test "GET /equipment/{slug}/weapons returns 404 for an unknown item" do
    assert_api_response :get, 404, path_params: {slug: "nope-nope"}
  end
end
