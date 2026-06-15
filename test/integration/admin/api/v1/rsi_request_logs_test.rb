# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::RsiRequestLogsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/rsi-request-logs" do
    get("RSI Request Logs list") do
      operationId "rsiRequestLogs"
      tags "RsiRequestLogs"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: RsiRequestLog.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "cacheId", in: :query, schema: {type: :string}, required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/RsiRequestLogs"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/rsi-request-logs/{id}/resolve" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "RSI Request Log id", required: true

    put("Resolve RSI Request Log") do
      operationId "resolveRsiRequestLog"
      tags "RsiRequestLogs"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/RsiRequestLog"
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
    @user = create(:admin_user, resource_access: [:"rsi-api-status"])
  end

  test "GET /rsi-request-logs lists logs" do
    RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /rsi-request-logs returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /rsi-request-logs returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "PUT /rsi-request-logs/:id/resolve resolves the log" do
    log = RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")
    sign_in @user

    assert_api_response :put, 200, path_params: {id: log.id}
  end

  test "PUT /rsi-request-logs/:id/resolve returns 401 when not signed in" do
    log = RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")

    assert_api_response :put, 401, path_params: {id: log.id}
  end

  test "PUT /rsi-request-logs/:id/resolve returns 403 for admin without access" do
    log = RsiRequestLog.create!(url: "https://robertsspaceindustries.com/test")
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: log.id}
  end
end
