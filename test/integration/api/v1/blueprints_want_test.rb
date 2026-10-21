# frozen_string_literal: true

require "openapi_helper"

class Api::V1::BlueprintsWantTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  PATH = "/blueprints/{slug}/want"

  api_path PATH do
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Put a blueprint on the wishlist") do
      operationId "wantBlueprint"
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

    delete("Take a blueprint off the wishlist") do
      operationId "unwantBlueprint"
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
  end

  setup do
    @user = create(:user)
    @blueprint = create(:blueprint, name: "Bulldog Repeater", sc_key: "bp_craft_behr_repeater_s3")
  end

  test "PUT puts the recipe on the wishlist" do
    sign_in @user

    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert UserBlueprint.find_by!(user: @user, blueprint: @blueprint).wanted
  end

  test "PUT twice leaves one mark" do
    sign_in @user

    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}
    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_equal 1, UserBlueprint.where(user: @user, blueprint: @blueprint).count
  end

  # Wanting what you already have is not a demotion.
  test "PUT on a held recipe keeps it held" do
    create(:user_blueprint, user: @user, blueprint: @blueprint)
    sign_in @user

    assert_api_response :put, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_equal [false], UserBlueprint.where(user: @user, blueprint: @blueprint).pluck(:wanted)
  end

  test "DELETE takes the recipe off the wishlist" do
    create(:user_blueprint, :wanted, user: @user, blueprint: @blueprint)
    sign_in @user

    assert_api_response :delete, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_empty UserBlueprint.where(user: @user)
  end

  test "DELETE leaves a held recipe alone" do
    create(:user_blueprint, user: @user, blueprint: @blueprint)
    sign_in @user

    assert_api_response :delete, 204, api_path: PATH, path_params: {slug: @blueprint.slug}

    assert_equal [@blueprint], @user.reload.blueprints.to_a
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

  test "DELETE on a recipe that does not exist is a 404" do
    sign_in @user

    assert_api_response :delete, 404, api_path: PATH, path_params: {slug: "no-such-recipe"}
  end
end
