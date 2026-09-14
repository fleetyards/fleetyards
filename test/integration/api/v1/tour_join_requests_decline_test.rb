# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TourJoinRequestsDeclineTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{tourSlug}/join-requests/{id}/decline" do
    parameter name: "tourSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Decline Tour Join Request") do
      operationId "declineTourJoinRequest"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::TourJoinRequest
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(409, "cannot be declined") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    @organiser = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@organiser], members: [@member])

    @tour = create(:tour, fleet: @fleet, created_by: @organiser)
    create(:payout_ledger, subject: @tour)

    @join_request = create(:tour_join_request, tour: @tour, user: @member)
  end

  def path_params
    {tourSlug: @tour.slug, id: @join_request.id}
  end

  test "PUT answers the request without touching the ledger" do
    sign_in @organiser

    assert_no_difference "PayoutParticipant.count" do
      assert_api_response :put, 200, path_params: path_params do
        assert_equal "declined", parsed_body["status"]
      end
    end
  end

  test "PUT is refused for the asker" do
    sign_in @member

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT is refused once the request has been answered" do
    @join_request.decline_by(@organiser)
    sign_in @organiser

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params
  end
end
