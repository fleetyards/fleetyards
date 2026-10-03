# frozen_string_literal: true

require "openapi_helper"

class Api::V1::LocationsPeopleTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/locations/{slug}/people" do
    get("Location people") do
      operationId "locationPeople"
      description "The reader's friends and fleet mates at the place or inside it. A token lists fleet mates only with the fleet or fleet:read scope"
      tags "Locations"
      produces "application/json"

      parameter name: "slug", in: :path, schema: {type: :string}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["public"]},
        {OpenId: ["public"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::LocationPeople
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
    Flipper.enable("friends")

    @stanton = create(:location, name: "Stanton System", kind: "system")
    @hurston = create(:location, name: "Hurston", kind: "planet", parent: @stanton, system: @stanton)
    @lorville = create(:location, name: "Lorville", kind: "city", parent: @hurston, system: @stanton)
    @clinic = create(:location, name: "Lorville Clinic", kind: "clinic", parent: @lorville, system: @stanton)
    @arccorp = create(:location, name: "ArcCorp", kind: "planet", parent: @stanton, system: @stanton)

    @reader = create(:user, current_location: @lorville)
    @fleet = create(:fleet, name: "Ninetails Hunters")
    create(:fleet_membership, :accepted, fleet: @fleet, user: @reader)
  end

  test "GET /locations/{slug}/people lists friends and fleet mates at the place or inside it" do
    friend = create(:user, username: "alpha", current_location: @clinic)
    create(:friendship, :accepted, requester: @reader, addressee: friend)

    mate = create(:user, username: "bravo", current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: @fleet, user: mate)
    create(:friendship, :accepted, requester: mate, addressee: @reader)

    elsewhere = create(:user, current_location: @arccorp)
    create(:friendship, :accepted, requester: @reader, addressee: elsewhere)

    sign_in @reader

    assert_api_response :get, 200, params: {slug: @hurston.slug} do
      people = parsed_body["people"]

      assert_equal %w[alpha bravo], people.pluck("username")
      alpha, bravo = people

      assert_equal "lorville-clinic", alpha.dig("currentLocation", "slug")
      assert alpha["friend"]
      assert_empty alpha["fleets"]

      assert_equal "lorville", bravo.dig("currentLocation", "slug")
      assert bravo["friend"]
      assert_equal ["Ninetails Hunters"], bravo["fleets"].pluck("name")
    end

    assert_api_response :get, 200, params: {slug: @stanton.slug} do
      assert_equal 3, parsed_body["people"].size
    end
  end

  test "GET /locations/{slug}/people leaves out the reader and anyone not already shown to them" do
    pending = create(:user, current_location: @lorville)
    create(:friendship, requester: pending, addressee: @reader)

    requested = create(:user, current_location: @lorville)
    create(:fleet_membership, :requested, fleet: @fleet, user: requested)

    left = create(:user, current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: @fleet, user: left, discarded_at: Time.current)

    stranger_fleet = create(:fleet)
    stranger = create(:user, current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: stranger_fleet, user: stranger)

    sign_in @reader

    assert_api_response :get, 200, params: {slug: @lorville.slug} do
      assert_empty parsed_body["people"]
    end
  end

  test "GET /locations/{slug}/people shows fleet mates only where the reader may read the roster" do
    mate = create(:user, current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: @fleet, user: mate)
    @reader.fleet_memberships.find_by(fleet: @fleet).fleet_role.update!(resource_access: [])

    sign_in @reader

    assert_api_response :get, 200, params: {slug: @lorville.slug} do
      assert_empty parsed_body["people"]
    end
  end

  test "GET /locations/{slug}/people shows no friends while the feature is off" do
    Flipper.disable("friends")
    friend = create(:user, current_location: @lorville)
    create(:friendship, :accepted, requester: @reader, addressee: friend)
    mate = create(:user, current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: @fleet, user: mate)

    sign_in @reader

    assert_api_response :get, 200, params: {slug: @lorville.slug} do
      assert_equal [[mate.username, false]], parsed_body["people"].map { |person| person.values_at("username", "friend") }
    end
  end

  test "GET /locations/{slug}/people shows fleet mates to a token only with a fleet scope" do
    friend = create(:user, current_location: @lorville)
    create(:friendship, :accepted, requester: @reader, addressee: friend)
    mate = create(:user, current_location: @lorville)
    create(:fleet_membership, :accepted, fleet: @fleet, user: mate)

    narrow = create(:oauth_access_token, resource_owner_id: @reader.id, scopes: ["public"])
    assert_api_response :get, 200, params: {slug: @lorville.slug}, headers: {"Authorization" => "Bearer #{narrow.token}"} do
      assert_equal [friend.username], parsed_body["people"].pluck("username")
    end

    wide = create(:oauth_access_token, resource_owner_id: @reader.id, scopes: ["public", "fleet:read"])
    assert_api_response :get, 200, params: {slug: @lorville.slug}, headers: {"Authorization" => "Bearer #{wide.token}"} do
      assert_equal [friend.username, mate.username].sort, parsed_body["people"].pluck("username").sort
    end
  end

  test "GET /locations/{slug}/people answers 401 to an expired or revoked token" do
    expired = create(:oauth_access_token, resource_owner_id: @reader.id, scopes: ["public"], created_at: 3.hours.ago)
    revoked = create(:oauth_access_token, resource_owner_id: @reader.id, scopes: ["public"], revoked_at: 1.minute.ago)

    [expired, revoked].each do |token|
      assert_api_response :get, 401, params: {slug: @lorville.slug}, headers: {"Authorization" => "Bearer #{token.token}"}
    end
  end

  test "GET /locations/{slug}/people answers for the session, not a token sent beside it" do
    friend = create(:user, username: "alpha", current_location: @lorville)
    create(:friendship, :accepted, requester: @reader, addressee: friend)

    other = create(:user)
    other_friend = create(:user, username: "bravo", current_location: @lorville)
    create(:friendship, :accepted, requester: other, addressee: other_friend)
    token = create(:oauth_access_token, resource_owner_id: other.id, scopes: ["public"], created_at: 3.hours.ago)

    sign_in @reader

    assert_api_response :get, 200, params: {slug: @lorville.slug}, headers: {"Authorization" => "Bearer #{token.token}"} do
      assert_equal ["alpha"], parsed_body["people"].pluck("username")
    end
  end

  test "GET /locations/{slug}/people answers 401 to an anonymous reader" do
    assert_api_response :get, 401, params: {slug: @lorville.slug}
  end

  test "GET /locations/{slug}/people answers 404 for an unknown place" do
    sign_in @reader

    assert_api_response :get, 404, params: {slug: "port-olisar"}
  end
end
