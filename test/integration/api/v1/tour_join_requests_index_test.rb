# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TourJoinRequestsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{tourSlug}/join-requests" do
    parameter name: "tourSlug", in: :path, schema: {type: :string}

    get("List Tour Join Requests") do
      operationId "tourJoinRequests"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::TourJoinRequestsList
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
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    @organiser = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@organiser], officers: [@officer], members: [@member])

    @tour = create(:tour, fleet: @fleet, created_by: @organiser)
    create(:payout_ledger, subject: @tour)

    @join_request = create(:tour_join_request, tour: @tour, user: @member)
  end

  def path_params
    {tourSlug: @tour.slug}
  end

  test "GET lists the pending requests for the organiser" do
    sign_in @organiser

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@join_request.id], parsed_body.map { |item| item["id"] }
      assert_equal @member.username, parsed_body.first["user"]["username"]
    end
  end

  test "GET lists them for a fleet payout manager" do
    sign_in @officer

    assert_api_response :get, 200, path_params: path_params do
      assert_equal [@join_request.id], parsed_body.map { |item| item["id"] }
    end
  end

  # A declined request is the record of the answer, not something still waiting
  # on one.
  test "GET leaves an answered request out" do
    @join_request.decline_by(@organiser)
    sign_in @organiser

    assert_api_response :get, 200, path_params: path_params do
      assert_empty parsed_body
    end
  end

  # They can read the tour, and their own standing on it is on the tour
  # payload -- the queue of who else is asking is the deciders' business.
  test "GET is refused to a member who cannot answer" do
    sign_in @member

    assert_api_response :get, 403, path_params: path_params
  end

  # The tour is addressed by its own slug here, so an outsider is refused by
  # TourPolicy#show? rather than by the fleet failing to resolve.
  test "GET is refused to somebody outside the fleet" do
    sign_in create(:user)

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET is refused when the feature is off" do
    Flipper.disable("tour_payouts")
    sign_in @organiser

    assert_api_response :get, 403, path_params: path_params
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: path_params
  end
end
