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

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("components")

    @component = create(:component, name: "Bulldog Repeater", sc_key: "behr_repeater_s3")
  end

  test "GET /components/{slug} returns the component" do
    assert_api_response :get, 200, params: {slug: @component.slug} do
      assert_equal "Bulldog Repeater", parsed_body["name"]
      assert_equal "bulldog-repeater", parsed_body["slug"]
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
  # The catalogue's own surface is gated while it is being built. `index` and
  # `weapons` are not: they answered long before this flag existed.
  test "GET /components/{slug} is forbidden while the flag is off" do
    Flipper.disable("components")

    assert_api_response :get, 403, params: {slug: @component.slug}
  end
end
