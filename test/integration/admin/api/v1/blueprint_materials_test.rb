# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::BlueprintMaterialsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/blueprints/material_filters" do
    get("Blueprint materials") do
      operationId "blueprintMaterials"
      tags "Blueprints"
      produces "application/json"

      response(200, "successful") do
        schema ::Shared::V1::Schemas::FilterOptionsList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:blueprints])
  end

  # The materials recipes actually consume, not the whole commodity catalogue:
  # 37 of the 232 commodities appear in a recipe, so a select built from the
  # catalogue would offer 195 options that can only ever come back empty.
  test "GET /blueprints/material_filters returns only the commodities a recipe consumes" do
    consumed = create(:commodity, name: "Titanium")
    create(:commodity, name: "Astatine")
    slot = create(:blueprint_cost_slot, build: create(:blueprint).build)
    create(:blueprint_cost_option, slot:, commodity: consumed)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal [consumed.slug], parsed_body.map { |filter| filter["value"] }
      assert_equal ["Titanium"], parsed_body.map { |filter| filter["label"] }
      assert(parsed_body.all? { |filter| filter["category"] == "material" })
    end
  end

  test "GET /blueprints/material_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /blueprints/material_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
