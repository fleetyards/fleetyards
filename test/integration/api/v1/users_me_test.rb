# frozen_string_literal: true

require "openapi_helper"

class Api::V1::UsersMeTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/users/me" do
    delete("Destroy Account") do
      operationId "destroyAccount"
      tags "Users"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      parameter name: :destroy_fleets, in: :query, required: false, schema: {type: :boolean},
        description: "Also destroy fleets where the user is the sole admin but other members exist"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/StandardMessage"
      end

      response(400, "blocked by permanent fleet role") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "bad request") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("My Data") do
      operationId "me"
      tags "Users"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/User"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("Update My Data") do
      operationId "updateProfile"
      tags "Users"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/UserUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: []},
        {OpenId: []}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/User"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  # DELETE /users/me
  test "DELETE /users/me destroys the account" do
    user = create(:user)
    sign_in user

    assert_api_response :delete, 200
  end

  test "DELETE /users/me when sole fleet admin" do
    user = create(:user)
    create(:fleet, admins: [user])
    sign_in user

    assert_api_response :delete, 200
  end

  test "DELETE /users/me with destroy_fleets=true removes multi-member fleet" do
    user = create(:user)
    other = create(:user)
    create(:fleet, admins: [user], members: [other])
    sign_in user

    assert_api_response :delete, 200, params: {destroy_fleets: true}
  end

  test "DELETE /users/me returns 400 when blocked by permanent fleet role" do
    user = create(:user)
    other = create(:user)
    create(:fleet, admins: [user], members: [other])
    sign_in user

    assert_api_response :delete, 400
  end

  test "DELETE /users/me returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  # GET /users/me
  test "GET /users/me returns the current user" do
    user = create(:user)
    sign_in user

    assert_api_response :get, 200 do
      assert_equal user.username, parsed_body["username"]
    end
  end

  test "GET /users/me returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  # PUT /users/me
  test "PUT /users/me updates the profile" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 200, body: {discord: "DiscordServer"} do
      assert_equal "DiscordServer", parsed_body["discord"]
    end
  end

  test "PUT /users/me returns 401 when not signed in" do
    assert_api_response :put, 401, body: {discord: "x"}
  end

  # OAuth Bearer token variants.
  test "DELETE /users/me with OAuth bearer token" do
    user = create(:user)

    assert_api_response :delete, 200, headers: oauth_headers_for(user, scopes: ["public"])
  end

  test "GET /users/me with OAuth bearer token" do
    user = create(:user)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["public"])
  end

  test "PUT /users/me with OAuth bearer token" do
    user = create(:user)

    assert_api_response :put, 200, headers: oauth_headers_for(user, scopes: ["public"]), body: {discord: "DiscordServer"}
  end
end
