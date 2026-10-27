# frozen_string_literal: true

require "openapi_helper"

class Api::V1::RafflesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [{SessionCookie: []}].freeze

  api_path "/raffles" do
    get("Raffles") do
      operationId "raffles"
      tags "Raffles"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Raffle.default_per_page}, required: false

      response(200, "successful") { schema ::V1::Schemas::Raffles }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/raffles/{id}" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    get("Raffle") do
      operationId "raffle"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::Raffle }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/raffles/{id}/entrants" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    get("Raffle entrants") do
      operationId "raffleEntrants"
      tags "Raffles"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: RaffleEntry.default_per_page}, required: false

      response(200, "successful") { schema ::V1::Schemas::RaffleEntrants }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/raffles/{id}/claim" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    post("Claim the raffle's gift code") do
      operationId "claimRaffle"
      tags "Raffles"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema ::Shared::V1::Schemas::RaffleGiftCode }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/raffles/{id}/code" do
    parameter name: "id", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    get("The claimed gift code") do
      operationId "raffleCode"
      tags "Raffles"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema ::Shared::V1::Schemas::RaffleGiftCode }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  api_path "/raffles/{raffleId}/entry" do
    parameter name: "raffleId", in: :path, description: "Raffle id", schema: {type: :string, format: :uuid}

    post("Enter Raffle") do
      operationId "enterRaffle"
      tags "Raffles"
      consumes "application/json"
      produces "application/json"
      security SECURITY

      request_body required: true, schema: ::V1::Schemas::Inputs::RaffleEntryInput

      response(201, "successful") { schema ::V1::Schemas::Raffle }
      response(400, "bad request") { schema ::Shared::V1::Schemas::ValidationError }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end

    delete("Withdraw from Raffle") do
      operationId "withdrawFromRaffle"
      tags "Raffles"
      produces "application/json"
      security SECURITY

      response(200, "successful") { schema ::V1::Schemas::Raffle }
      response(401, "unauthorized") { schema ::Shared::V1::Schemas::StandardError }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
    end
  end

  setup do
    Flipper.enable(:raffles)
    @user = create(:user)
    @raffle = create(:raffle, code: "THE-GIFT-CODE")
  end

  test "GET /raffles lists published raffles to anyone" do
    create(:raffle, :draft)

    assert_api_response :get, 200 do
      assert_equal [@raffle.id], parsed_body["items"].map { |raffle| raffle["id"] }
      assert_not parsed_body["items"].first["entered"]
      assert_equal Raffle::CONTACTS[:discord_handle], parsed_body["items"].first.dig("contacts", "discordHandle")
      assert_not_includes response.body, "THE-GIFT-CODE"
    end
  end

  test "GET /raffles is forbidden while the feature is off" do
    Flipper.disable(:raffles)

    assert_api_response :get, 403
  end

  test "GET /raffles/:id marks the reader's own entry" do
    create(:raffle_entry, raffle: @raffle, user: @user)
    sign_in @user

    assert_api_response :get, 200, api_path: "/raffles/{id}", path_params: {id: @raffle.id} do
      assert parsed_body["entered"]
      assert_equal 1, parsed_body["entriesCount"]
    end
  end

  test "GET /raffles/:id shows the current winner and forfeited winners" do
    raffle = create(:raffle, :closed, drawn_at: 3.weeks.ago)
    first = create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 3.weeks.ago, claim_deadline_at: 1.week.ago, forfeited_at: 1.week.ago)
    second = create(:raffle_entry, :after_close, raffle:, draw_position: 2, won_at: 1.week.ago, claim_deadline_at: 1.week.from_now)

    assert_api_response :get, 200, api_path: "/raffles/{id}", path_params: {id: raffle.id} do
      assert_equal second.user.username, parsed_body.dig("currentWinner", "username")
      assert_equal [first.user.username], parsed_body["forfeitedWinners"].map { |winner| winner["username"] }
    end
  end

  test "GET /raffles/:id hides a draft" do
    assert_api_response :get, 404, api_path: "/raffles/{id}", path_params: {id: create(:raffle, :draft).id}
  end

  test "GET /raffles/:id/entrants lists every entrant by name" do
    entries = create_list(:raffle_entry, 2, raffle: @raffle)

    assert_api_response :get, 200, api_path: "/raffles/{id}/entrants", path_params: {id: @raffle.id} do
      assert_equal entries.map { |entry| entry.user.username }.sort, parsed_body["items"].map { |entrant| entrant["username"] }.sort
    end
  end

  test "GET /raffles/:id/entrants returns 404 for a draft" do
    assert_api_response :get, 404, api_path: "/raffles/{id}/entrants", path_params: {id: create(:raffle, :draft).id}
  end

  test "POST /raffles/:raffle_id/entry enters with accepted conditions" do
    sign_in @user

    assert_api_response :post, 201, path_params: {raffleId: @raffle.id}, body: {conditionsAccepted: true} do
      assert parsed_body["entered"]
    end

    entry = @raffle.entries.find_by(user: @user)
    assert_equal Raffle::CONDITIONS_VERSION, entry.conditions_version
    assert_equal @user.email, entry.email
  end

  test "POST /raffles/:raffle_id/entry refuses without accepted conditions" do
    sign_in @user

    assert_api_response :post, 400, path_params: {raffleId: @raffle.id}, body: {conditionsAccepted: false}
  end

  test "POST /raffles/:raffle_id/entry refuses a second entry" do
    create(:raffle_entry, raffle: @raffle, user: @user)
    sign_in @user

    assert_api_response :post, 400, path_params: {raffleId: @raffle.id}, body: {conditionsAccepted: true}
  end

  test "POST /raffles/:raffle_id/entry refuses a closed raffle" do
    sign_in @user

    assert_api_response :post, 400, path_params: {raffleId: create(:raffle, :closed).id}, body: {conditionsAccepted: true}
  end

  test "POST /raffles/:raffle_id/entry returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {raffleId: @raffle.id}, body: {conditionsAccepted: true}
  end

  test "POST /raffles/:raffle_id/entry returns 404 for a draft" do
    sign_in @user

    assert_api_response :post, 404, path_params: {raffleId: create(:raffle, :draft).id}, body: {conditionsAccepted: true}
  end

  test "DELETE /raffles/:raffle_id/entry withdraws while the raffle is open" do
    create(:raffle_entry, raffle: @raffle, user: @user)
    sign_in @user

    assert_api_response :delete, 200, path_params: {raffleId: @raffle.id} do
      assert_not parsed_body["entered"]
      assert_equal 0, parsed_body["entriesCount"]
    end
  end

  test "DELETE /raffles/:raffle_id/entry is forbidden after the raffle closed" do
    create(:raffle_entry, raffle: @raffle, user: @user)
    @raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
    sign_in @user

    assert_api_response :delete, 403, path_params: {raffleId: @raffle.id}
  end

  test "DELETE /raffles/:raffle_id/entry returns 404 without an entry" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {raffleId: @raffle.id}
  end

  test "DELETE /raffles/:raffle_id/entry returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {raffleId: @raffle.id}
  end

  test "POST /raffles/:id/claim hands the winner the code" do
    raffle, = drawn_raffle_won_by(@user)
    sign_in @user

    assert_api_response :post, 200, path_params: {id: raffle.id} do
      assert_equal "THE-GIFT-CODE", parsed_body["code"]
    end

    assert raffle.reload.concluded?
  end

  test "POST /raffles/:id/claim refuses after the deadline" do
    raffle, = drawn_raffle_won_by(@user, claim_deadline_at: 1.minute.ago)
    sign_in @user

    assert_api_response :post, 400, path_params: {id: raffle.id}
  end

  test "POST /raffles/:id/claim is forbidden to anybody but the winner" do
    raffle, = drawn_raffle_won_by(create(:user))
    sign_in @user

    assert_api_response :post, 403, path_params: {id: raffle.id}
  end

  test "POST /raffles/:id/claim returns 401 when not signed in" do
    raffle, = drawn_raffle_won_by(@user)

    assert_api_response :post, 401, path_params: {id: raffle.id}
  end

  test "POST /raffles/:id/claim returns 404 for a missing raffle" do
    sign_in @user

    assert_api_response :post, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /raffles/:id/code shows a claimed code again" do
    raffle, entry = drawn_raffle_won_by(@user)
    entry.claim!
    sign_in @user

    assert_api_response :get, 200, api_path: "/raffles/{id}/code", path_params: {id: raffle.id} do
      assert_equal "THE-GIFT-CODE", parsed_body["code"]
    end
  end

  test "GET /raffles/:id/code refuses before the claim" do
    raffle, = drawn_raffle_won_by(@user)
    sign_in @user

    assert_api_response :get, 400, api_path: "/raffles/{id}/code", path_params: {id: raffle.id}
  end

  test "GET /raffles/:id/code is forbidden to anybody but the winner" do
    raffle, entry = drawn_raffle_won_by(create(:user))
    entry.claim!
    sign_in @user

    assert_api_response :get, 403, api_path: "/raffles/{id}/code", path_params: {id: raffle.id}
  end

  test "GET /raffles/:id/code returns 401 when not signed in" do
    raffle, = drawn_raffle_won_by(@user)

    assert_api_response :get, 401, api_path: "/raffles/{id}/code", path_params: {id: raffle.id}
  end

  test "GET /raffles/:id/code returns 404 for a missing raffle" do
    sign_in @user

    assert_api_response :get, 404, api_path: "/raffles/{id}/code", path_params: {id: SecureRandom.uuid}
  end

  private def drawn_raffle_won_by(user, claim_deadline_at: 5.days.from_now)
    raffle = create(:raffle, :closed, drawn_at: 1.hour.ago, code: "THE-GIFT-CODE")
    entry = create(:raffle_entry, :after_close, raffle:, user:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at:)
    [raffle, entry]
  end
end
