# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TourJoinRequestsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{tourSlug}/join-requests" do
    parameter name: "tourSlug", in: :path, schema: {type: :string}

    post("Ask To Join Tour") do
      operationId "createTourJoinRequest"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(201, "created") do
        schema ::V1::Schemas::Payouts::TourJoinRequest
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
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
    @ledger = create(:payout_ledger, subject: @tour)
  end

  def path_params
    {tourSlug: @tour.slug}
  end

  test "POST records a member's ask" do
    sign_in @member

    assert_difference "TourJoinRequest.count", 1 do
      assert_api_response :post, 201, path_params: path_params do
        assert_equal "pending", parsed_body["status"]
        assert_equal @member.username, parsed_body["user"]["username"]
      end
    end
  end

  # Asking is a membership right, not a payout one -- the whole point of the
  # flow is the member who holds none.
  test "POST is allowed for a member with no payout privileges" do
    @fleet.default_member_role.update!(resource_access: [])
    sign_in @member

    assert_api_response :post, 201, path_params: path_params
  end

  # Nothing about the ledger moves until somebody answers.
  test "POST leaves the participant list alone" do
    sign_in @member

    assert_no_difference "PayoutParticipant.count" do
      assert_api_response :post, 201, path_params: path_params
    end
  end

  test "POST refuses a second ask while the first is unanswered" do
    create(:tour_join_request, tour: @tour, user: @member)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params
  end

  # The answer was no; asking again is allowed, which is why only pending rows
  # are constrained.
  test "POST allows asking again after a decline" do
    create(:tour_join_request, :declined, tour: @tour, user: @member)
    sign_in @member

    assert_api_response :post, 201, path_params: path_params
  end

  test "POST refuses somebody already on the tour" do
    create(:payout_participant, payout_ledger: @ledger, user: @member)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params
  end

  test "POST refuses a settled tour" do
    @tour.update!(status: "settled", settled_at: Time.current)
    sign_in @member

    assert_api_response :post, 400, path_params: path_params
  end

  test "POST is refused to somebody outside the fleet" do
    sign_in create(:user)

    assert_api_response :post, 403, path_params: path_params
  end

  # There is no list a stranger could have found it in, so there is nobody to
  # ask -- the invite link is the only way onto one.
  test "POST refuses a standalone tour" do
    standalone = create(:tour, created_by: @member)
    create(:payout_ledger, subject: standalone)
    sign_in @member

    assert_api_response :post, 403, path_params: {tourSlug: standalone.slug}
  end

  test "POST is refused when the feature is off" do
    Flipper.disable("tour_payouts")
    sign_in @member

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST is refused when the fleet flag is off" do
    Flipper.disable("fleet_tours")
    sign_in @member

    assert_api_response :post, 403, path_params: path_params
  end

  test "POST returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: path_params
  end
end
