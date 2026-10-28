# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsStatsModelsByManufacturerTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/stats/models-by-manufacturer" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "username"

    get("Public Hangar Models by Manufacturer") do
      operationId "publicHangarModelsByManufacturer"
      tags "PublicHangarStats"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::PieChartStatsList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /public/hangars/:username/stats/models-by-manufacturer returns chart data" do
    user = create(:user, public_hangar_stats: true, vehicle_count: 3)

    assert_api_response :get, 200, path_params: {username: user.username}
  end

  test "GET /public/hangars/:username/stats/models-by-manufacturer returns 404 for non-public stats" do
    user = create(:user, public_hangar_stats: false)

    assert_api_response :get, 404, path_params: {username: user.username}
  end

  test "GET /public/hangars/:username/stats/models-by-manufacturer leaves out manufacturers only on the wishlist" do
    owner = create(:user, public_hangar_stats: true)
    owned = create(:vehicle, user: owner, public: true)
    wanted = create(:vehicle, :wanted, user: owner)

    get "/api/v1/public/hangars/#{owner.username}/stats/models-by-manufacturer"

    names = response.parsed_body.map { |point| point["name"] }
    assert_includes names, owned.model.manufacturer.name
    assert_not_includes names, wanted.model.manufacturer.name
  end
end
