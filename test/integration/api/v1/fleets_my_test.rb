# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsMyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/my" do
    get("Fleets for current User") do
      operationId "myFleets"
      tags "Fleets"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/Fleet"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "GET /fleets/my returns the user's admin and member fleets" do
    create(:fleet, admins: [@user])
    create(:fleet, members: [@user])
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET /fleets/my returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /fleets/my with OAuth bearer token" do
    create(:fleet, admins: [@user])

    assert_api_response :get, 200, headers: oauth_headers_for(@user, scopes: ["fleet", "fleet:read"])
  end
end
