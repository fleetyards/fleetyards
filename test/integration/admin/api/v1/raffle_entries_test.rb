# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::RaffleEntriesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/raffles/{raffleId}/entries" do
    parameter name: "raffleId", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    get("Raffle entries") do
      operationId "raffleEntries"
      tags "Raffles"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: RaffleEntry.default_per_page}, required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::RaffleEntries
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:admin_user, resource_access: [:raffles])
    @raffle = create(:raffle, :closed, drawn_at: 1.hour.ago, code: "THE-GIFT-CODE")
    @winner = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now, claim_mail_status: "delivered")
    @runner_up = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 2)
  end

  test "GET /raffles/:raffle_id/entries lists entries in draw order with masked emails" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {raffleId: @raffle.id} do
      assert_equal [1, 2], parsed_body["items"].map { |entry| entry["drawPosition"] }
      assert_not_includes response.body, @winner.email
      assert_not_includes response.body, "THE-GIFT-CODE"
      assert parsed_body["items"].first["maskedEmail"].include?("***")
      assert_equal "delivered", parsed_body["items"].first["claimMailStatus"]
    end
  end

  test "GET /raffles/:raffle_id/entries warns about entries that may be one person" do
    @winner.user.update_columns(current_sign_in_ip: "203.0.113.7", email: "pilot+1@example.com", created_at: 1.year.ago)
    @runner_up.user.update_columns(last_sign_in_ip: "203.0.113.7", email: "pilot+2@example.com", created_at: @runner_up.created_at - 1.hour)
    sign_in @admin

    assert_api_response :get, 200, path_params: {raffleId: @raffle.id} do
      winner, runner_up = parsed_body["items"]
      assert_equal [@runner_up.user.username], winner["sharedIpWith"]
      assert_equal [@winner.user.username], runner_up["sameInboxAs"]
      assert_not winner["newAccount"]
      assert runner_up["newAccount"]
    end
  end

  test "GET /raffles/:raffle_id/entries returns 404 for missing raffle" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {raffleId: SecureRandom.uuid}
  end

  test "GET /raffles/:raffle_id/entries returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {raffleId: @raffle.id}
  end

  test "GET /raffles/:raffle_id/entries returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {raffleId: @raffle.id}
  end
end
