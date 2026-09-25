# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclesMoveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL
  include ActionCable::TestHelper

  openapi_schema :"v1/schema"

  api_path "/vehicles/{id}/move" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Vehicle id"

    put("Move Vehicle") do
      operationId "moveVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleMoveInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful") do
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

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
    @alpha = create(:vehicle, user: @user, name: "Alpha")
    @bravo = create(:vehicle, user: @user, name: "Bravo")
    @charlie = create(:vehicle, user: @user, name: "Charlie")
  end

  def names
    @user.vehicles.ranked.pluck(:name)
  end

  test "PUT /vehicles/:id/move places a vehicle after another" do
    sign_in @user

    assert_api_response :put, 204,
      path_params: {id: @alpha.id},
      body: {afterId: @bravo.id} do
      assert_equal %w[Bravo Alpha Charlie], names
    end
  end

  test "PUT /vehicles/:id/move places a vehicle before another" do
    sign_in @user

    assert_api_response :put, 204,
      path_params: {id: @charlie.id},
      body: {beforeId: @alpha.id} do
      assert_equal %w[Charlie Alpha Bravo], names
    end
  end

  test "PUT /vehicles/:id/move after the last vehicle puts it last" do
    sign_in @user

    assert_api_response :put, 204,
      path_params: {id: @alpha.id},
      body: {afterId: @charlie.id} do
      assert_equal %w[Bravo Charlie Alpha], names
    end
  end

  # The wishlist shares the rank group with the hangar, so a place counted from
  # what the hangar shows would land on the wrong side of it.
  test "PUT /vehicles/:id/move lands next to the neighbour across vehicles the hangar does not show" do
    create(:vehicle, user: @user, name: "Wished", wanted: true)
    sign_in @user

    assert_api_response :put, 204,
      path_params: {id: @alpha.id},
      body: {afterId: @charlie.id} do
      assert_equal %w[Bravo Charlie Alpha Wished], names
    end
  end

  # An import creates its ships quietly, and a move must still reach every open
  # hangar of their owner.
  test "PUT /vehicles/:id/move tells the owner's open hangars about a ship an import created" do
    @alpha.update_column(:notify, false)
    sign_in @user

    assert_broadcasts(HangarChannel.broadcasting_for(@user), 1) do
      assert_api_response :put, 204,
        path_params: {id: @alpha.id},
        body: {afterId: @bravo.id}
    end
  end

  # Until the backfill has run, a hangar can still hold vehicles with no rank:
  # the move ranks them first, so the neighbour has a place to be counted from.
  test "PUT /vehicles/:id/move ranks a hangar that has none yet before placing the vehicle" do
    Vehicle.where(user: @user).update_all(rank: nil)
    sign_in @user

    assert_api_response :put, 204,
      path_params: {id: @alpha.id},
      body: {afterId: @charlie.id} do
      assert_equal %w[Bravo Charlie Alpha], names
      assert_empty @user.vehicles.where(rank: nil)
    end
  end

  test "PUT /vehicles/:id/move needs exactly one neighbour" do
    sign_in @user

    assert_api_response :put, 400,
      path_params: {id: @alpha.id},
      body: {afterId: @bravo.id, beforeId: @charlie.id}

    assert_api_response :put, 400,
      path_params: {id: @alpha.id},
      body: {}

    assert_equal %w[Alpha Bravo Charlie], names
  end

  test "PUT /vehicles/:id/move refuses the vehicle as its own neighbour" do
    sign_in @user

    assert_api_response :put, 400,
      path_params: {id: @alpha.id},
      body: {afterId: @alpha.id}
  end

  test "PUT /vehicles/:id/move does not move another user's vehicle" do
    other = create(:vehicle)
    sign_in @user

    assert_api_response :put, 404,
      path_params: {id: other.id},
      body: {afterId: @bravo.id}

    assert_equal other.rank, other.reload.rank
  end

  test "PUT /vehicles/:id/move does not place a vehicle next to another user's vehicle" do
    other = create(:vehicle)
    sign_in @user

    assert_api_response :put, 404,
      path_params: {id: @alpha.id},
      body: {afterId: other.id}

    assert_equal %w[Alpha Bravo Charlie], names
  end

  test "PUT /vehicles/:id/move returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {id: @alpha.id},
      body: {afterId: @bravo.id}
  end

  test "PUT /vehicles/:id/move with OAuth bearer token" do
    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      path_params: {id: @alpha.id},
      body: {afterId: @bravo.id}
  end

  test "PUT /vehicles/:id/move returns 401 for a token with the wrong scope" do
    assert_api_response :put, 401,
      headers: oauth_headers_for(@user, scopes: ["hangar:read"]),
      path_params: {id: @alpha.id},
      body: {afterId: @bravo.id}
  end
end
