# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarGroupsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/groups" do
    post("HangarGroup create") do
      operationId "createHangarGroup"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarGroupCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    get("HangarGroup list") do
      operationId "hangarGroups"
      tags "HangarGroups"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/hangar/groups/sort" do
    put("HangarGroup sort") do
      operationId "hangarGroupSort"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarGroupSortInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  api_path "/hangar/groups/{id}" do
    parameter name: "id", in: :path, description: "HangarGroup ID", schema: {type: :string, format: :uuid}, required: true

    delete("HangarGroup Destroy") do
      operationId "destroyHangarGroup"
      tags "HangarGroups"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    put("HangarGroup Update") do
      operationId "updateHangarGroup"
      tags "HangarGroups"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarGroupUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarGroup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /hangar/groups creates a group" do
    sign_in @user

    assert_api_response :post, 201, body: {name: "Hangar Group One Test", color: "#000000"} do
      assert_equal "Hangar Group One Test", parsed_body["name"]
    end
  end

  test "POST /hangar/groups returns 401 when not signed in" do
    assert_api_response :post, 401, body: {name: "x", color: "#000000"}
  end

  test "GET /hangar/groups lists groups" do
    create_list(:hangar_group, 3, user: @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body.size
    end
  end

  test "GET /hangar/groups returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "PUT /hangar/groups/sort reorders groups" do
    groups = create_list(:hangar_group, 3, user: @user)
    sign_in @user

    assert_api_response :put, 200, body: {sorting: groups.reverse.map(&:id)} do
      groups.reverse.each_with_index do |group, index|
        assert_equal index, group.reload.sort
      end
    end
  end

  test "PUT /hangar/groups/sort returns 401 when not signed in" do
    groups = create_list(:hangar_group, 3, user: @user)

    assert_api_response :put, 401, body: {sorting: groups.map(&:id)}
  end

  test "DELETE /hangar/groups/:id removes the group" do
    group = create(:hangar_group, user: @user)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: group.id}
  end

  test "DELETE /hangar/groups/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /hangar/groups/:id returns 403 for a different user's group" do
    group = create(:hangar_group, user: @user)
    sign_in create(:user)

    assert_api_response :delete, 403, path_params: {id: group.id}
  end

  test "DELETE /hangar/groups/:id returns 401 when not signed in" do
    group = create(:hangar_group, user: @user)

    assert_api_response :delete, 401, path_params: {id: group.id}
  end

  test "PUT /hangar/groups/:id updates the group" do
    group = create(:hangar_group, user: @user)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: group.id}, body: {name: "Hangar Group One Test"} do
      assert_equal "Hangar Group One Test", parsed_body["name"]
    end
  end

  test "PUT /hangar/groups/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {name: "x"}
  end

  test "PUT /hangar/groups/:id returns 403 for a different user's group" do
    group = create(:hangar_group, user: @user)
    sign_in create(:user)

    assert_api_response :put, 403, path_params: {id: group.id}, body: {name: "x"}
  end

  test "PUT /hangar/groups/:id returns 401 when not signed in" do
    group = create(:hangar_group, user: @user)

    assert_api_response :put, 401, path_params: {id: group.id}, body: {name: "x"}
  end

  # OAuth Bearer token variants.
  test "POST /hangar/groups with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Hangar Group OAuth", color: "#000000"}
  end

  test "GET /hangar/groups with OAuth bearer token" do
    create_list(:hangar_group, 3, user: @user)

    assert_api_response :get, 200, headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end

  test "PUT /hangar/groups/sort with OAuth bearer token" do
    groups = create_list(:hangar_group, 3, user: @user)

    assert_api_response :put, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {sorting: groups.reverse.map(&:id)}
  end

  test "DELETE /hangar/groups/:id with OAuth bearer token" do
    group = create(:hangar_group, user: @user)

    assert_api_response :delete, 200,
      path_params: {id: group.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end

  test "PUT /hangar/groups/:id with OAuth bearer token" do
    group = create(:hangar_group, user: @user)

    assert_api_response :put, 200,
      path_params: {id: group.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Updated Group"}
  end
end
