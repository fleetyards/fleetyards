# frozen_string_literal: true

require "openapi_helper"

class Api::V1::GameEventsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/game-events" do
    get("Game events list") do
      operationId "gameEvents"
      tags "Game Events"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: GameEvent.default_per_page}, required: false

      response(200, "successful") do
        schema ::V1::Schemas::GameEvents
      end
    end
  end

  test "GET /game-events lists published events that are running or to come, soonest first" do
    later = create(:game_event, title: "Later", starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    running = create(:game_event, title: "Running", starts_at: 1.day.ago, ends_at: 3.days.from_now)
    create(:game_event, :draft, title: "Draft")
    create(:game_event, :past, title: "Past")

    assert_api_response :get, 200 do
      assert_equal [running.id, later.id], parsed_body["items"].pluck("id")
    end
  end

  # RSI opens some events without saying when they close; the end is set once
  # it is announced.
  test "GET /game-events keeps an event without an end until one is set" do
    open_ended = create(:game_event, starts_at: 12.days.ago, ends_at: nil)
    create(:game_event, starts_at: 12.days.ago, ends_at: 2.days.ago)

    assert_api_response :get, 200 do
      assert_equal [open_ended.id], parsed_body["items"].pluck("id")
    end
  end

  test "GET /game-events carries the cover image when one is uploaded" do
    game_event = create(:game_event, starts_at: 1.day.from_now)
    game_event.cover_image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: "cover.png", content_type: "image/png"
    )

    assert_api_response :get, 200 do
      assert parsed_body["items"].sole.dig("coverImage", "url").present?
    end
  end
end
