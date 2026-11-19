# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FeaturesBetaTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/features/beta" do
    get("Feature Flags Users or Fleets Can Toggle") do
      operationId "betaFeatures"
      tags "Features"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::FeatureNamesList
      end
    end
  end

  test "GET /features/beta lists the flags with a user or fleet toggle" do
    FeatureSetting.create!(feature_name: "hangar_planner", self_service_user: true)
    FeatureSetting.create!(feature_name: "fleet_logistics", self_service_fleet: true)
    FeatureSetting.create!(feature_name: "starmap")

    assert_api_response :get, 200 do
      assert_equal %w[fleet_logistics hangar_planner], parsed_body
    end
  end

  test "GET /features/beta leaves out a toggle for a flag no longer in the registry" do
    FeatureSetting.create!(feature_name: "retired_flag", self_service_user: true)

    assert_api_response :get, 200 do
      assert_empty parsed_body
    end
  end
end
