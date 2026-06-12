# frozen_string_literal: true

require_relative "../../../../openapi_helper"

class Admin::Api::V1::ManufacturersOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/manufacturers/options" do
    get("Manufacturer Options") do
      operationId "manufacturerOptions"
      tags "Manufacturers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: {type: :object, "$ref": "#/components/schemas/ManufacturerQuery"}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/ManufacturerOptions"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:admin_user, resource_access: [:manufacturers])
  end

  test "GET /manufacturers/options returns id/name/slug/logo for each manufacturer" do
    create_list(:manufacturer, 6, :with_logo)
    sign_in @user

    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 6, items.count
      assert_equal %w[id name slug logo].sort, items.first.keys.sort
    end
  end

  test "GET /manufacturers/options returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /manufacturers/options returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
