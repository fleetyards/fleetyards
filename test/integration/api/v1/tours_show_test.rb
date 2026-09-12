# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Show Tour") do
      operationId "tour"
      tags "Tours"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user"]},
        {OpenId: ["user"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Payouts::Tour
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    patch("Update Tour") do
      operationId "updateTour"
      tags "Tours"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::TourUpdateInput, required: true

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

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    delete("Delete Tour") do
      operationId "destroyTour"
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

  test "GET returns the tour to its organiser with the invite token" do
    sign_in @organiser

    assert_api_response :get, 200, path_params: {slug: @tour.slug} do
      assert_equal @tour.invite_token, parsed_body["inviteToken"]
    end
  end

  test "GET returns the tour to a participant without the invite token" do
    sign_in @participant

    assert_api_response :get, 200, path_params: {slug: @tour.slug} do
      assert_nil parsed_body["inviteToken"]
    end
  end

  test "GET is refused for someone not on the tour" do
    sign_in @stranger

    assert_api_response :get, 403, path_params: {slug: @tour.slug}
  end

  test "GET returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {slug: @tour.slug}
  end

  test "PATCH renames the tour for its organiser" do
    sign_in @organiser

    assert_api_response :patch, 200, path_params: {slug: @tour.slug}, body: {title: "Renamed"} do
      assert_equal "Renamed", parsed_body["title"]
    end
  end

  test "PATCH is refused for a participant" do
    sign_in @participant

    assert_api_response :patch, 403, path_params: {slug: @tour.slug}, body: {title: "Renamed"}
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401, path_params: {slug: @tour.slug}, body: {title: "Renamed"}
  end

  test "DELETE removes the tour" do
    sign_in @organiser

    assert_api_response :delete, 200, path_params: {slug: @tour.slug} do
      assert_not Tour.exists?(@tour.id)
    end
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {slug: @tour.slug}
  end

  test "DELETE removes a tour whose ledger is settled" do
    ledger = @tour.payout_ledger
    organiser_participant = create(:payout_participant, payout_ledger: ledger, user: @organiser)
    other = create(:payout_participant, payout_ledger: ledger)
    create(:payout_entry, :income, payout_ledger: ledger,
      payout_participant: other, amount: 900)
    ledger.settle!(@organiser)

    sign_in @organiser

    assert_api_response :delete, 200, path_params: {slug: @tour.slug} do
      assert_not Tour.exists?(@tour.id)
      assert_not PayoutLedger.exists?(ledger.id)
      assert_not PayoutParticipant.exists?(organiser_participant.id)
    end
  end
end
