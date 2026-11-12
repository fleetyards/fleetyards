# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LandingServicesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/landing-services" do
    get("Landing services") do
      operationId "landingServices"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::LandingServicesList
      end
    end
  end

  test "GET /landing-services lists each service in order, with its icon" do
    LandingService.create!(key: "repair")
    rearm = LandingService.create!(key: "rearm")
    rearm.icon.attach(io: File.open(Rails.root.join("test/fixtures/files/vector.svg")), filename: "vector.svg", content_type: "image/svg+xml")

    assert_api_response :get, 200 do
      assert_equal %w[repair rearm], parsed_body.pluck("key")
      assert_nil parsed_body.first["icon"]
      assert_equal "vector.svg", parsed_body.second.dig("icon", "name")
    end
  end
end
