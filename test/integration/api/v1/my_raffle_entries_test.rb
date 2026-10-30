# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MyRaffleEntriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/my-raffle-entries" do
    get("My raffle entries") do
      operationId "myRaffleEntries"
      tags "Raffles"
      produces "application/json"
      security [{SessionCookie: []}]

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: RaffleEntry.default_per_page}, required: false

      response(200, "successful") { schema ::V1::Schemas::MyRaffleEntries }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    @user = create(:user)
  end

  test "GET /my-raffle-entries lists only the reader's entries with their outcome" do
    open_entry = create(:raffle_entry, user: @user)
    drawn = create(:raffle, :closed, drawn_at: 1.hour.ago)
    won = create(:raffle_entry, :after_close, raffle: drawn, user: @user, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)
    create(:raffle_entry)
    sign_in @user

    assert_api_response :get, 200 do
      outcomes = parsed_body["items"].to_h { |item| [item["id"], item["outcome"]] }
      assert_equal({open_entry.id => "open", won.id => "won"}, outcomes)
    end
  end

  test "GET /my-raffle-entries returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
