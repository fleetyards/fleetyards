# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsContentsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}/contents" do
    get("Location contents") do
      operationId "locationContents"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      response(200, "successful") do
        schema ::V1::Schemas::LocationContents
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @nyx = create(:location, name: "Nyx", kind: "star")
    3.times { |index| create(:location, name: "QV Logistics Station", sc_key: "kaboos_#{index}", kind: "outpost", parent: @nyx, shown_on_starmap: index.zero?) }
    create(:location, name: "Pyro Gateway", kind: "station", parent: @nyx)
    create(:location, name: "Delamar", kind: "moon", parent: @nyx)
  end

  test "GET /locations/{slug}/contents groups by kind and folds namesakes together" do
    assert_api_response :get, 200, params: {slug: @nyx.slug} do
      groups = parsed_body["groups"]

      assert_equal %w[moon station outpost], groups.pluck("kind")

      outposts = groups.last
      assert_equal 3, outposts["count"]
      assert_equal [["QV Logistics Station", 3, true]], outposts["entries"].map { |entry| entry.values_at("name", "count", "shownOnStarmap") }
    end
  end
end
