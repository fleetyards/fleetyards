# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VersionTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/version" do
    get("Version of Fleetyards") do
      operationId "version"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/Version"
      end
    end
  end

  test "GET /version returns successfully" do
    assert_api_response :get, 200
  end
end
