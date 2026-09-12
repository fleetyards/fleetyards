# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PayoutParticipantsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/payouts/{payoutLedgerId}/participants" do
    parameter name: "payoutLedgerId", in: :path, schema: {type: :string, format: :uuid}

    post("Add a payout participant") do
      operationId "createPayoutParticipant"
      tags "Payouts"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::PayoutParticipantCreateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Payouts::PayoutParticipant
      end

      response(400, "invalid") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "unknown username") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("List payout participants") do
      operationId "payoutParticipants"
      tags "Payouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::PayoutParticipantsList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")

    @organiser = create(:user)
    @member = create(:user)
    @outsider = create(:user)

    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: @ledger, user: @organiser)
    @member_participant = create(:payout_participant, payout_ledger: @ledger, user: @member)
  end

  test "POST adds a participant by username" do
    sign_in @organiser

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: {username: @outsider.username} do
      assert_equal @outsider.username, parsed_body["displayName"]
      assert_equal false, parsed_body["guest"]
    end
  end

  test "POST adds a guest by name" do
    sign_in @organiser

    assert_api_response :post, 201,
      path_params: {payoutLedgerId: @ledger.id},
      body: {name: "Kev"} do
      assert_equal "Kev", parsed_body["displayName"]
      assert_equal true, parsed_body["guest"]
      assert_nil parsed_body["user"]
    end
  end

  test "POST returns 404 for an unknown username" do
    sign_in @organiser

    assert_api_response :post, 404,
      path_params: {payoutLedgerId: @ledger.id},
      body: {username: "nobody-here-at-all"}
  end

  test "POST rejects a participant with neither a username nor a name" do
    sign_in @organiser

    assert_api_response :post, 400,
      path_params: {payoutLedgerId: @ledger.id},
      body: {name: ""}
  end

  test "POST rejects adding the same user twice" do
    sign_in @organiser

    assert_api_response :post, 400,
      path_params: {payoutLedgerId: @ledger.id},
      body: {username: @member.username}
  end

  # Adding someone re-divides everyone's share, so it stays with the organiser
  # even though a participant may record their own entries.
  test "POST is refused for a plain participant" do
    sign_in @member

    assert_api_response :post, 403,
      path_params: {payoutLedgerId: @ledger.id},
      body: {name: "Kev"}
  end

  test "POST returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {payoutLedgerId: @ledger.id},
      body: {name: "Kev"}
  end

  test "GET lists the participants" do
    sign_in @member

    assert_api_response :get, 200, path_params: {payoutLedgerId: @ledger.id} do
      assert_equal 2, parsed_body.size
    end
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {payoutLedgerId: @ledger.id}
  end
end
