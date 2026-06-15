# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ScDataVersionTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/sc-data/version" do
    get("SC Data Version") do
      operationId "scDataVersion"
      tags "Versions"
      produces "application/json"

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/ScDataVersion"
      end
    end
  end

  setup do
    create(:import, :scdata_all, aasm_state: :finished, version: "1.0.0")
  end

  test "GET /sc-data/version returns the finished import version" do
    assert_api_response :get, 200
  end
end
