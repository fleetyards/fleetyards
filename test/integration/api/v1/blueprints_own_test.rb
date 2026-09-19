# frozen_string_literal: true

require "openapi_helper"

class Api::V1::BlueprintsOwnTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PATH = "/blueprints/{slug}/own"

  api_path PATH do
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Mark a blueprint as owned") do
      operationId "ownBlueprint"
      tags "Blueprints"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Drop a blueprint's owned mark") do
      operationId "unownBlueprint"
      tags "Blueprints"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @blueprint = create(:blueprint, name: "Bulldog Repeater", sc_key: "bp_craft_behr_repeater_s3")
  end

  test "PUT marks the recipe as held" do
    sign_in @user

    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_equal [@blueprint], @user.reload.blueprints.to_a
  end

  # Holding a recipe is a state rather than an event, so the second click is
  # the same answer as the first -- not a duplicate row and not a 400 the
  # client has to interpret.
  test "PUT twice leaves one mark" do
    sign_in @user

    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}
    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_equal 1, UserBlueprint.where(user: @user, blueprint: @blueprint).count
  end

  test "DELETE drops the mark" do
    create(:user_blueprint, user: @user, blueprint: @blueprint)
    sign_in @user

    assert_api_response :delete, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_empty @user.reload.blueprints
  end

  # Unmarking something never marked is the state that was asked for.
  test "DELETE without a mark succeeds" do
    sign_in @user

    assert_api_response :delete, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_empty @user.reload.blueprints
  end

  test "PUT without a session is refused" do
    assert_api_response :put, 401, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_empty UserBlueprint.all
  end

  test "DELETE without a session is refused" do
    assert_api_response :delete, 401, api_path: PATH, path_params: {slug: @blueprint.slug}
  end

  test "PUT on a recipe that does not exist is a 404" do
    sign_in @user

    assert_api_response :put, 404, api_path: PATH, path_params: {slug: "no-such-recipe"}
  end
end
