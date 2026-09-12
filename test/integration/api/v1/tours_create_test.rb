# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours" do
    post("Create Tour") do
      operationId "createTour"
      tags "Tours"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::TourCreateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::Tour
      end

      response(400, "invalid") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @user = create(:user)
  end

  test "POST /tours creates a tour with a ledger and the organiser on it" do
    sign_in @user

    assert_api_response :post, 201, body: {title: "Jumptown Run", description: "Quick one"} do
      assert_equal "Jumptown Run", parsed_body["title"]
      assert_equal "open", parsed_body["status"]
      assert_not_nil parsed_body["payoutLedgerId"]

      tour = Tour.find(parsed_body["id"])
      assert_equal [@user.id], tour.payout_ledger.payout_participants.pluck(:user_id)
    end
  end

  test "POST /tours returns the invite token to its organiser" do
    sign_in @user

    assert_api_response :post, 201, body: {title: "Jumptown Run"} do
      assert_not_nil parsed_body["inviteToken"]
    end
  end

  test "POST /tours rejects a tour with no title" do
    sign_in @user

    assert_api_response :post, 400, body: {title: ""}
  end

  test "POST /tours with an OAuth bearer token" do
    assert_api_response :post, 201,
      body: {title: "Jumptown Run"},
      headers: oauth_headers_for(@user, scopes: ["user:write"])
  end

  test "POST /tours returns 401 for a token with the wrong scope" do
    assert_api_response :post, 401,
      body: {title: "Jumptown Run"},
      headers: oauth_headers_for(@user, scopes: ["public"])
  end

  test "POST /tours returns 401 when not signed in" do
    assert_api_response :post, 401, body: {title: "Jumptown Run"}
  end
end
