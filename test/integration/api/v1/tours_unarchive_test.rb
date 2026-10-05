# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ToursUnarchiveTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/tours/{slug}/unarchive" do
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Unarchive Tour") do
      operationId "unarchiveTour"
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
    @organiser = create(:user)
    @participant = create(:user)

    @tour = create(:tour, created_by: @organiser)
    ledger = create(:payout_ledger, subject: @tour)
    create(:payout_participant, payout_ledger: ledger, user: @organiser)
    create(:payout_participant, payout_ledger: ledger, user: @participant)
  end

  test "PUT unarchive brings the tour back" do
    @tour.archive!
    sign_in @organiser

    assert_api_response :put, 200, path_params: {slug: @tour.slug} do
      assert_equal false, parsed_body["archived"]
      assert_nil @tour.reload.archived_at
    end
  end

  test "PUT unarchive is refused for a participant" do
    @tour.archive!
    sign_in @participant

    assert_api_response :put, 403, path_params: {slug: @tour.slug}
  end

  test "PUT unarchive returns 401 when not signed in" do
    assert_api_response :put, 401, path_params: {slug: @tour.slug}
  end
end
