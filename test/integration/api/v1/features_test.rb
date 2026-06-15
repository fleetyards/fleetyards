# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FeaturesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/features" do
    get("Feature Flags for User") do
      operationId "features"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema type: :array, items: {type: :string}
      end
    end
  end

  setup do
    Flipper.enable("NewFeature")
  end

  test "GET /features returns the enabled feature flags" do
    assert_api_response :get, 200 do
      assert_equal ["NewFeature"], parsed_body
    end
  end
end
