# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::GameEventsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/game-events" do
    post("Create Game Event") do
      operationId "createGameEvent"
      tags "GameEvents"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::GameEventInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameEvent
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end

    get("Game Events list") do
      operationId "gameEvents"
      tags "GameEvents"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: GameEvent.default_per_page}, required: false
      parameter "$ref": "#/components/parameters/SortingParameter"
      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::GameEventQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameEvents
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path "/game-events/{id}" do
    parameter name: "id", in: :path, description: "Game Event id", schema: {type: :string, format: :uuid}

    delete("Destroy Game Event") do
      operationId "destroyGameEvent"
      tags "GameEvents"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameEvent
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

    get("Game Event Detail") do
      operationId "gameEvent"
      tags "GameEvents"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameEvent
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

    put("Update Game Event") do
      operationId "updateGameEvent"
      tags "GameEvents"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::Admin::V1::Schemas::Inputs::GameEventInput

      response(200, "successful") do
        schema ::Admin::V1::Schemas::GameEvent
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
    @user = create(:admin_user, resource_access: [:game_events])
  end

  test "POST /game-events creates a game event" do
    sign_in @user

    body = {title: "Invictus Launch Week", category: "ship_combat", startsAt: 1.day.from_now.utc.iso8601, published: true}

    assert_api_response :post, 200, body: body do
      assert_equal "Invictus Launch Week", parsed_body["title"]
      assert_equal "ship_combat", parsed_body["category"]
      assert parsed_body["published"]
    end
  end

  test "POST /game-events rejects an end before the start" do
    sign_in @user

    body = {title: "Backwards", startsAt: 2.days.from_now.utc.iso8601, endsAt: 1.day.from_now.utc.iso8601}

    assert_api_response :post, 400, body: body
  end

  test "POST /game-events returns 401 when not signed in" do
    assert_api_response :post, 401, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601}
  end

  test "POST /game-events returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :post, 403, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601}
  end

  test "GET /game-events lists game events" do
    create_list(:game_event, 3)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /game-events returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /game-events returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end

  test "DELETE /game-events/:id destroys the game event" do
    game_event = create(:game_event)
    sign_in @user

    assert_api_response :delete, 200, path_params: {id: game_event.id}
  end

  test "DELETE /game-events/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {id: SecureRandom.uuid}
  end

  test "DELETE /game-events/:id returns 401 when not signed in" do
    game_event = create(:game_event)

    assert_api_response :delete, 401, path_params: {id: game_event.id}
  end

  test "DELETE /game-events/:id returns 403 for admin without access" do
    game_event = create(:game_event)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :delete, 403, path_params: {id: game_event.id}
  end

  test "GET /game-events/:id returns the game event" do
    game_event = create(:game_event)
    sign_in @user

    assert_api_response :get, 200, path_params: {id: game_event.id}
  end

  test "GET /game-events/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end

  test "GET /game-events/:id returns 401 when not signed in" do
    game_event = create(:game_event)

    assert_api_response :get, 401, path_params: {id: game_event.id}
  end

  test "GET /game-events/:id returns 403 for admin without access" do
    game_event = create(:game_event)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403, path_params: {id: game_event.id}
  end

  test "PUT /game-events/:id updates the game event" do
    game_event = create(:game_event)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: game_event.id}, body: {title: "Updated", startsAt: 1.day.from_now.utc.iso8601, published: false} do
      assert_equal "Updated", parsed_body["title"]
      assert_not parsed_body["published"]
    end
  end

  test "PUT /game-events/:id attaches a cover image" do
    game_event = create(:game_event)
    sign_in @user

    assert_api_response :put, 200, path_params: {id: game_event.id}, body: {title: game_event.title, startsAt: game_event.starts_at.utc.iso8601, coverImage: uploaded("cover.png", "test.png", "image/png").signed_id} do
      assert parsed_body.dig("coverImage", "url").present?
    end

    assert_equal "cover.png", game_event.reload.cover_image.filename.to_s
  end

  test "PUT /game-events/:id removes the cover image" do
    game_event = create(:game_event)
    game_event.cover_image.attach(uploaded("cover.png", "test.png", "image/png"))
    sign_in @user

    assert_api_response :put, 200, path_params: {id: game_event.id}, body: {title: game_event.title, startsAt: game_event.starts_at.utc.iso8601, coverImage: nil} do
      assert_nil parsed_body["coverImage"]
    end

    assert_not game_event.reload.cover_image.attached?
  end

  test "PUT /game-events/:id rejects a vector cover image" do
    game_event = create(:game_event)
    sign_in @user

    assert_api_response :put, 400, path_params: {id: game_event.id}, body: {title: game_event.title, startsAt: game_event.starts_at.utc.iso8601, coverImage: uploaded("cover.svg", "vector.svg", "image/svg+xml").signed_id}
  end

  test "PUT /game-events/:id returns 404 for missing id" do
    sign_in @user

    assert_api_response :put, 404, path_params: {id: SecureRandom.uuid}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601}
  end

  test "PUT /game-events/:id returns 401 when not signed in" do
    game_event = create(:game_event)

    assert_api_response :put, 401, path_params: {id: game_event.id}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601}
  end

  test "PUT /game-events/:id returns 403 for admin without access" do
    game_event = create(:game_event)
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :put, 403, path_params: {id: game_event.id}, body: {title: "Test", startsAt: 1.day.from_now.utc.iso8601}
  end

  private def uploaded(filename, fixture, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files", fixture)),
      filename:,
      content_type:
    )
  end
end
