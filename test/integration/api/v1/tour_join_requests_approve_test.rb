# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TourJoinRequestsApproveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{tourSlug}/join-requests/{id}/approve" do
    parameter name: "tourSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    put("Approve Tour Join Request") do
      operationId "approveTourJoinRequest"
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

      response(409, "cannot be approved") do
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
    @ledger = create(:payout_ledger, subject: @tour)

    @join_request = create(:tour_join_request, tour: @tour, user: @member)
  end

  def path_params
    {tourSlug: @tour.slug, id: @join_request.id}
  end

  # The answer and the participant row are one transaction: an approved request
  # with nobody on the list would read as "you are on the tour" while dividing
  # nothing to them.
  test "PUT puts the asker on the ledger" do
    sign_in @organiser

    assert_difference "PayoutParticipant.count", 1 do
      assert_api_response :put, 200, path_params: path_params do
        assert_equal "approved", parsed_body["status"]
        assert_equal @organiser.username, parsed_body["decidedBy"]["username"]
      end
    end

    assert @ledger.payout_participants.exists?(user_id: @member.id)
  end

  test "PUT is allowed for a fleet payout manager" do
    sign_in @officer

    assert_api_response :put, 200, path_params: path_params
  end

  test "PUT is refused for a member who cannot answer" do
    sign_in @member

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT is refused for somebody outside the fleet" do
    sign_in create(:user)

    assert_api_response :put, 403, path_params: path_params
  end

  test "PUT is refused once the request has been answered" do
    @join_request.decline_by(@organiser)
    sign_in @organiser

    assert_api_response :put, 403, path_params: path_params
  end

  # The shares were frozen when the transfers were computed, so a late arrival
  # cannot be added to a list that can no longer change.
  test "PUT conflicts once the tour is settled" do
    @ledger.settle!(@organiser)
    sign_in @organiser

    assert_no_difference "PayoutParticipant.count" do
      assert_api_response :put, 409, path_params: path_params do
        assert_equal "cannot_approve", parsed_body["code"]
      end
    end

    assert_predicate @join_request.reload, :pending?
  end

  test "PUT returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: path_params
  end
end
