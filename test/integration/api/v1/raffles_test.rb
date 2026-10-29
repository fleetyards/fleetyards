# frozen_string_literal: true

require "openapi_helper"

class Api::V1::RafflesTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  SECURITY = [{SessionCookie: []}].freeze

  api_path "/raffles/current" do
    get("Current Raffle") do
      operationId "currentRaffle"
      tags "Raffles"
      produces "application/json"

      response(200, "successful") { schema ::V1::Schemas::Raffle }
      response(403, "forbidden") { schema ::Shared::V1::Schemas::StandardError }
      response(404, "not found") { schema ::Shared::V1::Schemas::StandardError }
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

  test "GET /raffles/current shows the running raffle to anyone" do
    create(:raffle, :draft)
    create(:raffle, :upcoming)

    assert_api_response :get, 200, api_path: "/raffles/current" do
      assert_equal @raffle.id, parsed_body["id"]
      assert_not parsed_body["entered"]
      assert_equal Raffle::CONDITIONS_VERSION, parsed_body["conditionsVersion"]
      assert_not_includes response.body, "THE-GIFT-CODE"
    end
  end

  test "GET /raffles/current returns 404 without a published raffle" do
    @raffle.update_columns(published: false)

    assert_api_response :get, 404, api_path: "/raffles/current"
  end

  test "GET /raffles/current is forbidden while the feature is off" do
    Flipper.disable(:raffles)

    assert_api_response :get, 403, api_path: "/raffles/current"
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
    second = create(:raffle_entry, :after_close, raffle:, draw_position: 2, won_at: 1.week.ago, claim_deadline_at: 2.days.from_now)

    assert_api_response :get, 200, api_path: "/raffles/{id}", path_params: {id: raffle.id} do
      assert_equal second.user.username, parsed_body.dig("currentWinner", "username")
      assert_equal [first.user.username], parsed_body["forfeitedWinners"].map { |winner| winner["username"] }
    end
  end

  test "GET /raffles/:id hides a draft" do
    assert_api_response :get, 404, api_path: "/raffles/{id}", path_params: {id: create(:raffle, :draft).id}
  end

  test "GET /raffles/:id answers in the reader's language, falling back to English" do
    @raffle.update!(title: "Win a Polaris", prize: "Polaris game package", translations: {"de" => {"title" => "Gewinne eine Polaris"}})

    assert_api_response :get, 200, api_path: "/raffles/{id}", path_params: {id: @raffle.id}, headers: {"Accept-Language" => "de"} do
      assert_equal "Gewinne eine Polaris", parsed_body["title"]
      assert_equal "Polaris game package", parsed_body["prize"]
    end

    assert_api_response :get, 200, api_path: "/raffles/{id}", path_params: {id: @raffle.id}, headers: {"Accept-Language" => "fr"} do
      assert_equal "Win a Polaris", parsed_body["title"]
    end
  end

  test "GET /raffles/:id/entrants lists every entrant by name" do
    entries = create_list(:raffle_entry, 2, raffle: @raffle)

    assert_api_response :get, 200, api_path: "/raffles/{id}/entrants", path_params: {id: @raffle.id} do
      assert_equal entries.map { |entry| entry.user.username }.sort, parsed_body["items"].map { |entrant| entrant["username"] }.sort
    end
  end

  test "GET /raffles/:id/entrants lists the latest entrant first" do
    older = create(:raffle_entry, raffle: @raffle, created_at: 2.hours.ago)
    newer = create(:raffle_entry, raffle: @raffle, created_at: 1.hour.ago)

    assert_api_response :get, 200, api_path: "/raffles/{id}/entrants", path_params: {id: @raffle.id} do
      assert_equal [newer, older].map { |entry| entry.user.username }, parsed_body["items"].map { |entrant| entrant["username"] }
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
end
