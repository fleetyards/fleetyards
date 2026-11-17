# frozen_string_literal: true

require "openapi_helper"

class Api::V1::GalaxyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/galaxy" do
    get("Star systems and jump tunnels") do
      operationId "galaxy"
      tags "Locations"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Galaxy
      end
    end
  end

  setup do
    stanton = create(:star_system, code: "STANTON", name: "Stanton", in_game: true)
    magnus = create(:star_system, code: "MAGNUS", name: "Magnus", system_type: "binary", affiliations: [])
    create(:jump_tunnel, entry_system: stanton, exit_system: magnus, size: "large")
  end

  test "GET /galaxy returns every system and the tunnels between them by code" do
    assert_api_response :get, 200 do
      assert_equal %w[Magnus Stanton], parsed_body["systems"].pluck("name")
      assert parsed_body["systems"].find { |system| system["code"] == "STANTON" }["inGame"]
      assert_equal [{"entryCode" => "STANTON", "exitCode" => "MAGNUS", "size" => "large", "bidirectional" => true}], parsed_body["tunnels"]
    end
  end
end
