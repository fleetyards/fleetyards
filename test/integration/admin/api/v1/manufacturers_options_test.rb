# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::ManufacturersOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/manufacturers/options" do
    get("Manufacturer Options") do
      operationId "manufacturerOptions"
      tags "Manufacturers"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: :q, in: :query, schema: ::Admin::V1::Schemas::Queries::ManufacturerQuery, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Manufacturers::Options::ManufacturerOptions
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
    @user = create(:admin_user, resource_access: [:manufacturers])
  end

  test "GET /manufacturers/options returns id/name/slug/logo/icon for each manufacturer" do
    create_list(:manufacturer, 6, :with_logo, :with_icon)
    sign_in @user

    assert_api_response :get, 200 do
      items = parsed_body["items"]
      assert_equal 6, items.count
      assert_equal %w[id name slug logo icon].sort, items.first.keys.sort
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
