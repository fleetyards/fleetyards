# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours" do
    get("List Tours") do
      operationId "tours"
      tags "Tours"
      produces "application/json"

      parameter ::Shared::V1::Parameters::PageParameter
      parameter ::Shared::V1::Parameters::SortingParameter

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::ToursList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @participant = create(:user)
    @stranger = create(:user)

    @tour = create(:tour, created_by: @organiser)
    ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: ledger, user: @participant)
  end

  test "GET /tours lists the tours a user organises" do
    sign_in @organiser

    assert_api_response :get, 200 do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  test "GET /tours lists the tours a user is a participant of" do
    sign_in @participant

    assert_api_response :get, 200 do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # The relation scope is the only thing keeping other people's tours out, so
  # it gets its own case rather than riding on the two above.
  test "GET /tours hides a tour the user has nothing to do with" do
    sign_in @stranger

    assert_api_response :get, 200 do
      assert_empty parsed_body["items"]
    end
  end

  # The fleet's own page lists these, and it is now open to every member, so
  # repeating them here would show one trip in two places.
  test "GET /tours leaves out a tour owned by a fleet the user is in" do
    Flipper.enable("fleet_tours")
    fleet = create(:fleet, members: [@organiser])
    create(:tour, fleet: fleet, created_by: @organiser)

    sign_in @organiser

    assert_api_response :get, 200 do
      assert_equal [@tour.id], parsed_body["items"].map { |item| item["id"] }
    end
  end

  # They joined by invite link, and a fleet's page 404s for an outsider, so
  # this list is the only place left to find it.
  test "GET /tours keeps a tour of a fleet the user does not belong to" do
    Flipper.enable("fleet_tours")
    fleet_tour = create(:tour, :for_fleet, created_by: create(:user))
    ledger = create(:payout_ledger, subject: fleet_tour)
    create(:payout_participant, payout_ledger: ledger, user: @participant)

    sign_in @participant

    assert_api_response :get, 200 do
      assert_equal [@tour.id, fleet_tour.id].sort, parsed_body["items"].map { |item| item["id"] }.sort
    end
  end

  # The fleet page is what the exclusion above assumes is showing them, and
  # with fleet_tours off there is no such page -- so the tour has to stay here
  # or its own organiser cannot find it.
  test "GET /tours keeps a fleet's tours while fleet_tours is off" do
    fleet = create(:fleet, members: [@organiser])
    fleet_tour = create(:tour, fleet: fleet, created_by: @organiser)

    sign_in @organiser

    assert_api_response :get, 200 do
      assert_equal [@tour.id, fleet_tour.id].sort, parsed_body["items"].map { |item| item["id"] }.sort
    end
  end

  test "GET /tours withholds the invite token from a participant" do
    sign_in @participant

    assert_api_response :get, 200 do
      assert_nil parsed_body["items"].first["inviteToken"]
    end
  end

  test "GET /tours returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
