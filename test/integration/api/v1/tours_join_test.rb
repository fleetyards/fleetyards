# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursJoinTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/join/{token}" do
    parameter name: "token", in: :path, schema: {type: :string}

    post("Join Tour") do
      operationId "joinTour"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user:write"]},
        {OpenId: ["user:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::Tour
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(409, "already settled") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @joiner = create(:user)
    @tour = create(:tour, created_by: @organiser)
    @ledger = create(:payout_ledger, subject: @tour)
  end

  test "POST /tours/join/:token adds the user as a participant" do
    sign_in @joiner

    assert_api_response :post, 200, path_params: {token: @tour.invite_token} do
      assert_includes @ledger.reload.payout_participants.pluck(:user_id), @joiner.id
    end
  end

  test "POST /tours/join/:token is idempotent" do
    create(:payout_participant, payout_ledger: @ledger, user: @joiner)
    sign_in @joiner

    assert_api_response :post, 200, path_params: {token: @tour.invite_token} do
      assert_equal 1, @ledger.reload.payout_participants.where(user_id: @joiner.id).count
    end
  end

  test "POST /tours/join/:token refuses once the ledger is settled" do
    @ledger.update!(status: "settled", settled_at: Time.current)
    sign_in @joiner

    assert_api_response :post, 409, path_params: {token: @tour.invite_token}
  end

  test "POST /tours/join/:token returns 404 for an unknown token" do
    sign_in @joiner

    assert_api_response :post, 404, path_params: {token: "deadbeef"}
  end

  test "POST /tours/join/:token returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {token: @tour.invite_token}
  end
end
