# frozen_string_literal: true

require "openapi_helper"

class Api::V1::TourJoinRequestsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{tourSlug}/join-requests/{id}" do
    parameter name: "tourSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}

    delete("Withdraw Tour Join Request") do
      operationId "destroyTourJoinRequest"
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
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    Flipper.enable("fleet_tours")

    @organiser = create(:user)
    @member = create(:user)
    @other = create(:user)
    @fleet = create(:fleet, admins: [@organiser], members: [@member, @other])

    @tour = create(:tour, fleet: @fleet, created_by: @organiser)
    create(:payout_ledger, subject: @tour)

    @join_request = create(:tour_join_request, tour: @tour, user: @member)
  end

  def path_params
    {tourSlug: @tour.slug, id: @join_request.id}
  end

  test "DELETE withdraws the asker's own request" do
    sign_in @member

    assert_difference "TourJoinRequest.count", -1 do
      assert_api_response :delete, 200, path_params: path_params
    end
  end

  test "DELETE lets the organiser clear one off the list" do
    sign_in @organiser

    assert_difference "TourJoinRequest.count", -1 do
      assert_api_response :delete, 200, path_params: path_params
    end
  end

  test "DELETE is refused for another member" do
    sign_in @other

    assert_api_response :delete, 403, path_params: path_params
  end

  # An answered request is the record of the answer, and withdrawing it after
  # the fact would lose that.
  test "DELETE is refused once the request has been answered" do
    @join_request.decline_by(@organiser)
    sign_in @member

    assert_api_response :delete, 403, path_params: path_params
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: path_params
  end
end
