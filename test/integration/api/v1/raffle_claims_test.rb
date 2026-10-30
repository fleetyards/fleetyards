# frozen_string_literal: true

require "openapi_helper"

class Api::V1::RaffleClaimsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/raffle-claims" do
    post("Claim a raffle prize with the link from the claim mail") do
      operationId "claimRafflePrize"
      tags "Raffles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::RaffleClaimInput

      response(201, "claimed") { schema ::V1::Schemas::RaffleClaim }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    @raffle = create(:raffle, :closed, drawn_at: 1.hour.ago, code: "THE-GIFT-CODE")
    @entry = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)
  end

  test "POST /raffle-claims claims the win and queues the prize mail, without signing in" do
    assert_api_response :post, 201, body: {token: @entry.generate_token_for(:raffle_claim)} do
      assert_equal @raffle.id, parsed_body["raffleId"]
      assert_not_includes response.body, "THE-GIFT-CODE"
    end

    assert @entry.reload.claimed_at.present?
    assert_equal [@entry.id], Raffles::PrizeMailJob.jobs.last["args"]
  end

  test "POST /raffle-claims answers a second click with success and no second mail" do
    token = @entry.generate_token_for(:raffle_claim)
    @entry.claim!
    jobs = Raffles::PrizeMailJob.jobs.size

    assert_api_response :post, 201, body: {token:}

    assert_equal jobs, Raffles::PrizeMailJob.jobs.size
  end

  test "POST /raffle-claims refuses after the deadline" do
    token = @entry.generate_token_for(:raffle_claim)
    @entry.update_columns(claim_deadline_at: 1.minute.ago)

    assert_api_response :post, 400, body: {token:}

    assert_nil @entry.reload.claimed_at
  end

  test "POST /raffle-claims refuses an unknown token" do
    assert_api_response :post, 400, body: {token: "nope"}
  end

end
