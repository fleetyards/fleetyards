# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursArchiveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{slug}/archive" do
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Archive Tour") do
      operationId "archiveTour"
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

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("tour_payouts")
    @organiser = create(:user)
    @participant = create(:user)

    @tour = create(:tour, created_by: @organiser)
    ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: ledger, user: @organiser)
    create(:payout_participant, payout_ledger: ledger, user: @participant)
  end

  test "PUT archive keeps the tour and its ledger" do
    sign_in @organiser

    assert_api_response :put, 200, path_params: {slug: @tour.slug} do
      assert parsed_body["archived"]
      assert_not_nil parsed_body["archivedAt"]
      assert_equal 2, @tour.reload.payout_ledger.payout_participants.count
    end
  end

  test "PUT archive is refused for a participant" do
    sign_in @participant

    assert_api_response :put, 403, path_params: {slug: @tour.slug}

    assert_not @tour.reload.archived?
  end

  test "PUT archive returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {slug: @tour.slug}
  end
end
