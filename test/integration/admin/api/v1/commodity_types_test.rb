# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::CommodityTypesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/commodities/type_filters" do
    get("Commodity types") do
      operationId "commodityTypes"
      tags "Commodities"
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
    @user = create(:admin_user, resource_access: [:commodities])
  end

  test "GET /commodities/type_filters returns the types in use as filter options" do
    create(:commodity)
    create(:commodity, :mineral)

    sign_in @user

    assert_api_response :get, 200 do
      assert_equal %w[metal mineral], parsed_body.map { |filter| filter["value"] }
      assert(parsed_body.all? { |filter| filter["label"].present? })
      assert(parsed_body.all? { |filter| filter["category"] == "commodity_type" })
    end
  end

  # Unlike the slot list this one is the types the table actually holds, so a
  # type only last patch's commodities carried is not offered.
  test "GET /commodities/type_filters skips commodities from an older build" do
    create(:commodity, :mineral, version: "older-build")

    sign_in @user

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end

  test "GET /commodities/type_filters returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /commodities/type_filters returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
