# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ComponentsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/components/{slug}" do
    get("Component detail") do
      operationId "component"
      tags "Components"
      produces "application/json"

      parameter name: :slug, in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::Shared::V1::Schemas::Component
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @component = create(
      :component,
      name: "Bulldog Repeater",
      sc_key: "behr_repeater_s3",
      tags: ["BEHR", "LaserRepeater", "flightReady"],
      required_tags: ["Weapon_Gun"]
    )
  end

  test "GET /components/{slug} returns the component" do
    assert_api_response :get, 200, params: {slug: @component.slug} do
      assert_equal "Bulldog Repeater", parsed_body["name"]
      assert_equal "bulldog-repeater", parsed_body["slug"]
    end
  end

  # The two halves of "what fits where". `tags` was held back while the pushed
  # tree still carried the parser's re-encoded arrays, so this is also
  # the assertion that it is being published at all.
  test "GET /components/{slug} carries both halves of the port match" do
    assert_api_response :get, 200, params: {slug: @component.slug} do
      assert_equal ["BEHR", "LaserRepeater", "flightReady"], parsed_body["tags"]
      assert_equal ["Weapon_Gun"], parsed_body["requiredTags"]
    end
  end

  test "GET /components/{slug} serves what a countermeasure presents to a seeker" do
    launcher = create(:component, name: "Chaff Launcher", category: "countermeasures",
      type_data: {
        "fire_rate" => 50.0, "max_ammo" => 20,
        "countermeasure" => {
          "kind" => "noise", "lifetime" => 8.0, "spawn_delay" => 1.0,
          "infrared" => {"start" => 30000.0, "end" => 30000.0},
          "electromagnetic" => {"start" => 30000.0, "end" => 30000.0},
          "cross_section" => {"start" => 20000.0, "end" => 20000.0}
        }
      })

    assert_api_response :get, 200, params: {slug: launcher.slug} do
      countermeasure = parsed_body["typeData"]["countermeasure"]

      assert_equal "noise", countermeasure["kind"]
      assert_in_delta 8.0, countermeasure["lifetime"]
      assert_in_delta 20000.0, countermeasure["crossSection"]["start"]
    end
  end

  test "GET /components/{slug} carries the component's own ports" do
    assert_api_response :get, 200, params: {slug: @component.slug} do
      assert parsed_body.key?("hardpoints")
    end
  end

  test "GET /components/{slug} 404s for a slug nobody has" do
    assert_api_response :get, 404, params: {slug: "no-such-component"}
  end
end
