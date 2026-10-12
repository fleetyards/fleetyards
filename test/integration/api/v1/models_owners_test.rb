# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsOwnersTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/owners" do
    parameter name: "slug", in: :path, schema: {type: :string}, required: true

    get("Model Owners") do
      operationId "modelOwners"
      tags "Models"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Models::Owners::ModelOwners
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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
    Flipper.enable("vehicle_overview")
    @user = create(:user)
    @model = create(:model)
  end

  def befriend(other)
    create(:friendship, :accepted, requester: @user, addressee: other)
  end

  def fleet_with_another_owner(**reader_membership)
    fleet = create(:fleet)
    create(:fleet_membership, :accepted, fleet:, user: @user, **reader_membership)
    member = create(:user)
    create(:fleet_membership, :accepted, fleet:, user: member)
    FleetVehicle.find_or_create_by!(fleet:, vehicle: create(:vehicle, user: member, model: @model))
    fleet
  end

  test "GET /models/:slug/owners lists the reader's own ships of the model" do
    own = create(:vehicle, user: @user, model: @model, name: "Rust Bucket")
    create(:vehicle, user: @user, model: @model, wanted: true)
    create(:vehicle, user: @user, model: create(:model))
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal [own.id], parsed_body["vehicles"].pluck("id")
    end
  end

  test "GET /models/:slug/owners names friends whose hangar shows the model" do
    open_friend = create(:user, public_hangar: false, friends_hangar: true)
    create_list(:vehicle, 2, user: open_friend, model: @model, public: true)
    befriend(open_friend)
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal 1, parsed_body.dig("friends", "total")
      assert_equal [[open_friend.username, 2]], parsed_body.dig("friends", "items").map { [it["username"], it["count"]] }
    end
  end

  test "GET /models/:slug/owners leaves out a friend whose hangar is closed to friends" do
    closed_friend = create(:user, public_hangar: false, friends_hangar: false)
    create(:vehicle, user: closed_friend, model: @model, public: true)
    befriend(closed_friend)
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal 0, parsed_body.dig("friends", "total")
    end
  end

  test "GET /models/:slug/owners counts only a friend's public, bought ships" do
    friend = create(:user, public_hangar: true)
    create(:vehicle, user: friend, model: @model, public: false)
    create(:vehicle, user: friend, model: @model, public: true, wanted: true)
    create(:vehicle, user: friend, model: @model, public: true, loaner: true)
    befriend(friend)
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal 0, parsed_body.dig("friends", "total")
    end
  end

  test "GET /models/:slug/owners leaves out people who are not friends" do
    stranger = create(:user, public_hangar: true)
    create(:vehicle, user: stranger, model: @model, public: true)
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal 0, parsed_body.dig("friends", "total")
    end
  end

  test "GET /models/:slug/owners counts the model in the reader's fleets" do
    fleet = create(:fleet)
    create(:fleet_membership, :accepted, fleet:, user: @user)
    member = create(:user)
    create(:fleet_membership, :accepted, fleet:, user: member)
    FleetVehicle.find_or_create_by!(fleet:, vehicle: create(:vehicle, user: member, model: @model))
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      entry = parsed_body["fleets"].sole
      assert_equal fleet.slug, entry["slug"]
      assert_equal 1, entry["total"]
      assert_equal [member.username], entry["members"]
    end
  end

  test "GET /models/:slug/owners leaves out a fleet where only the reader flies the model" do
    solo = create(:fleet, name: "Solo")
    create(:fleet_membership, :accepted, fleet: solo, user: @user)
    shared = create(:fleet, name: "Shared")
    create(:fleet_membership, :accepted, fleet: shared, user: @user)
    member = create(:user)
    create(:fleet_membership, :accepted, fleet: shared, user: member)
    own = create(:vehicle, user: @user, model: @model)
    FleetVehicle.find_or_create_by!(fleet: solo, vehicle: own)
    FleetVehicle.find_or_create_by!(fleet: shared, vehicle: own)
    FleetVehicle.find_or_create_by!(fleet: shared, vehicle: create(:vehicle, user: member, model: @model))

    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      entry = parsed_body["fleets"].sole
      assert_equal shared.slug, entry["slug"]
      assert_equal 2, entry["total"]
      assert_equal [member.username], entry["members"]
    end
  end

  test "GET /models/:slug/owners counts but does not name a member hiding as owner" do
    fleet = create(:fleet)
    create(:fleet_membership, :accepted, fleet:, user: @user)
    hidden = create(:user, hide_owner: true)
    create(:fleet_membership, :accepted, fleet:, user: hidden)
    FleetVehicle.find_or_create_by!(fleet:, vehicle: create(:vehicle, user: hidden, model: @model))
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      entry = parsed_body["fleets"].sole
      assert_equal 1, entry["ownersTotal"]
      assert_empty entry["members"]
    end
  end

  test "GET /models/:slug/owners leaves out ships a member keeps from the fleet" do
    fleet = create(:fleet)
    create(:fleet_membership, :accepted, fleet:, user: @user)
    shown = create(:user)
    hidden = create(:user)
    create(:vehicle, user: shown, model: @model)
    create(:vehicle, user: hidden, model: @model)
    create(:fleet_membership, :accepted, fleet:, user: shown).setup_fleet_vehicles
    create(:fleet_membership, :accepted, :hide_ships, fleet:, user: hidden).setup_fleet_vehicles
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      entry = parsed_body["fleets"].sole
      assert_equal 1, entry["total"]
      assert_equal [shown.username], entry["members"]
    end
  end

  test "GET /models/:slug/owners leaves out a fleet the reader is only invited to" do
    fleet = create(:fleet)
    create(:fleet_membership, :invited, fleet:, user: @user)
    member = create(:user)
    create(:fleet_membership, :accepted, fleet:, user: member)
    FleetVehicle.find_or_create_by!(fleet:, vehicle: create(:vehicle, user: member, model: @model))
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_empty parsed_body["fleets"]
    end
  end

  # The membership rows outlive the fleet: only the fleet carries the discard.
  test "GET /models/:slug/owners leaves out a discarded fleet" do
    fleet_with_another_owner.update_columns(discarded_at: Time.current)
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_empty parsed_body["fleets"]
    end
  end

  test "GET /models/:slug/owners returns 404 for an unknown model" do
    sign_in @user

    assert_api_response :get, 404, path_params: {slug: "no-such-ship"}
  end

  test "GET /models/:slug/owners returns 403 while the feature is off" do
    Flipper.disable("vehicle_overview")
    sign_in @user

    assert_api_response :get, 403, path_params: {slug: @model.slug}
  end

  test "GET /models/:slug/owners returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {slug: @model.slug}
  end
end
