# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicFleetsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/fleets/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "slug"

    get("Fleet Detail") do
      operationId "publicFleet"
      tags "Fleets"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Fleet"
      end

      response(404, "not found if fleet is not public") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /public/fleets/:slug returns the fleet for the admin" do
    user = create(:user)
    fleet = create(:fleet, :with_description, :with_logo, :with_social_links, admins: [user])
    sign_in user

    assert_api_response :get, 200, path_params: {slug: fleet.slug}
  end

  test "GET /public/fleets/:slug returns the fleet for a member" do
    user = create(:user)
    fleet = create(:fleet, :with_description, members: [user])
    sign_in user

    assert_api_response :get, 200, path_params: {slug: fleet.slug}
  end

  test "GET /public/fleets/:slug returns the fleet for an unrelated signed-in user" do
    user = create(:user)
    fleet = create(:fleet, :with_description)
    sign_in user

    assert_api_response :get, 200, path_params: {slug: fleet.slug}
  end

  test "GET /public/fleets/:slug returns the fleet without a session" do
    fleet = create(:fleet, :with_description)

    assert_api_response :get, 200, path_params: {slug: fleet.slug}
  end

  test "GET /public/fleets/:slug returns 404 for private fleet" do
    fleet = create(:fleet, :private)

    assert_api_response :get, 404, path_params: {slug: fleet.slug}
  end

  test "GET /public/fleets/:slug returns 404 for unknown slug" do
    assert_api_response :get, 404, path_params: {slug: "unknown-fleet"}
  end
end
