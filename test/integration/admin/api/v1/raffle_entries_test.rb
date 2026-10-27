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

  api_path "/raffles/{raffleId}/entries/{id}/send-verification" do
    parameter name: "raffleId", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Raffle entry id", schema: {type: :string, format: :uuid}

    post("Send a verification code to the email the entrant entered with") do
      operationId "sendRaffleEntryVerification"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::MessageResponse
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
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

  api_path "/raffles/{raffleId}/entries/{id}/claim" do
    parameter name: "raffleId", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}
    parameter name: "id", in: :path, description: "Raffle entry id", schema: {type: :string, format: :uuid}

    post("Claim a win on behalf of a verified entrant") do
      operationId "claimRaffleEntry"
      tags "Raffles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::RaffleVerificationInput

      response(200, "successful") do
        schema ::Shared::V1::Schemas::RaffleGiftCode
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
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
    @winner = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 5.days.from_now)
    # Verification is the path for a winner whose account is gone.
    @winner.update_columns(user_id: nil, username: "gone")
    @runner_up = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 2)
  end

  test "GET /raffles/:raffle_id/entries lists entries in draw order with masked emails" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {raffleId: @raffle.id} do
      assert_equal [1, 2], parsed_body["items"].map { |entry| entry["drawPosition"] }
      assert_not_includes response.body, @winner.email
      assert parsed_body["items"].first["maskedEmail"].include?("***")
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

  test "POST send-verification mails a code to the snapshot email" do
    sign_in @admin
    RaffleMailer.expects(:verification_code)
      .with { |entry, code| entry.id == @winner.id && code.match?(/\A\d{6}\z/) }
      .returns(stub(deliver_now: true))

    assert_api_response :post, 200, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: @winner.id}

    assert @winner.reload.verification_code_digest.present?
  end

  test "POST send-verification refuses a winner who still has an account" do
    @winner.update_columns(user_id: create(:user).id)
    sign_in @admin

    assert_api_response :post, 400, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: @winner.id}
  end

  test "POST send-verification refuses an entry that is not the current winner" do
    sign_in @admin

    assert_api_response :post, 400, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: @runner_up.id}
  end

  test "POST send-verification returns 404 for missing entry" do
    sign_in @admin

    assert_api_response :post, 404, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: SecureRandom.uuid}
  end

  test "POST send-verification returns 401 when not signed in" do
    assert_api_response :post, 401, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: @winner.id}
  end

  test "POST send-verification returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, api_path: "/raffles/{raffleId}/entries/{id}/send-verification", path_params: {raffleId: @raffle.id, id: @winner.id}
  end

  test "POST claim with the right code hands out the gift code" do
    code = @winner.issue_verification_code!
    sign_in @admin

    assert_api_response :post, 200, api_path: "/raffles/{raffleId}/entries/{id}/claim", path_params: {raffleId: @raffle.id, id: @winner.id}, body: {verificationCode: code} do
      assert_equal "THE-GIFT-CODE", parsed_body["code"]
    end

    assert_equal @admin, @winner.reload.claimed_by
    assert @raffle.reload.concluded?
  end

  test "POST claim with a wrong code is refused" do
    code = @winner.issue_verification_code!
    sign_in @admin

    assert_api_response :post, 400, api_path: "/raffles/{raffleId}/entries/{id}/claim", path_params: {raffleId: @raffle.id, id: @winner.id}, body: {verificationCode: (code == "000000") ? "111111" : "000000"}

    assert_nil @winner.reload.claimed_at
  end

  test "POST claim returns 404 for missing entry" do
    sign_in @admin

    assert_api_response :post, 404, api_path: "/raffles/{raffleId}/entries/{id}/claim", path_params: {raffleId: @raffle.id, id: SecureRandom.uuid}, body: {verificationCode: "123456"}
  end

  test "POST claim returns 401 when not signed in" do
    assert_api_response :post, 401, api_path: "/raffles/{raffleId}/entries/{id}/claim", path_params: {raffleId: @raffle.id, id: @winner.id}, body: {verificationCode: "123456"}
  end

  test "POST claim returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, api_path: "/raffles/{raffleId}/entries/{id}/claim", path_params: {raffleId: @raffle.id, id: @winner.id}, body: {verificationCode: "123456"}
  end
end
