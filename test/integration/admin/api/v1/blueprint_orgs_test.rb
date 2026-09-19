# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::BlueprintOrgsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/blueprints/org_filters" do
    get("Blueprint orgs") do
      operationId "blueprintOrgs"
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

  # 130 of the 154 reward pools carry an org and the other 24 carry a pool name
  # alone, so an unattributed source contributes no option rather than a blank
  # one.
  test "GET /blueprints/org_filters returns the orgs that hand a recipe out" do
    build = create(:blueprint).build
    create(:blueprint_source, build:, org_name: "Eckhart Security", position: 1)
    create(:blueprint_source, :unattributed, build:, position: 2)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal ["Eckhart Security"], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["category"] == "org" })
    end
  end

  test "GET /blueprints/org_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /blueprints/org_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
