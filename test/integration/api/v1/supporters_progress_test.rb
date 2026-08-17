# frozen_string_literal: true

require "openapi_helper"

class Api::V1::SupportersProgressTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/supporters/progress" do
    get("Public Supporters Progress") do
      operationId "supportersProgress"
      tags "Supporters"
      produces "application/json"

      response(200, "successful") do
        schema "$ref": "#/components/schemas/SupportProgress"
      end
    end
  end

  test "GET /supporters/progress returns 200 with summed goal and contributions" do
    create(:funding_goal, title: "Server costs", amount_cents: 70_000, effective_from: 30.days.ago.to_date)
    create(:funding_goal, title: "Discord", amount_cents: 30_000, effective_from: 30.days.ago.to_date, description: "Discord Nitro")
    create(:funding_goal, title: "Retired", amount_cents: 99_999, effective_from: 90.days.ago.to_date, ended_at: 30.days.ago.to_date)
    create(:supporter_contribution, name: "Alice", amount_cents: 1_000, started_at: Date.current)
    create(:supporter_contribution, :anonymous, name: "Bob", amount_cents: 500, started_at: Date.current)
    create(:supporter_contribution, :recurring, name: "Carla", amount_cents: 2_500, started_at: 90.days.ago.to_date)
    create(:supporter_contribution, name: nil, amount_cents: 250, started_at: Date.current)

    assert_api_response :get, 200 do
      assert_equal 100_000, parsed_body["goal"]["amountCents"]
      assert_equal "EUR", parsed_body["goal"]["currency"]
      assert_equal 2, parsed_body["goal"]["items"].count
      titles = parsed_body["goal"]["items"].map { |g| g["title"] }
      assert_includes titles, "Server costs"
      assert_includes titles, "Discord"
      refute_includes titles, "Retired"
      assert_equal 4_250, parsed_body["monthlyTotal"]["amountCents"]
      assert_equal 4, parsed_body["contributions"].count

      anonymous_entry = parsed_body["contributions"].find { |c| c["amountCents"] == 500 }
      assert_equal "Anonymous", anonymous_entry["displayName"]

      named_entry = parsed_body["contributions"].find { |c| c["amountCents"] == 1_000 }
      assert_equal "Alice", named_entry["displayName"]

      nameless_entry = parsed_body["contributions"].find { |c| c["amountCents"] == 250 }
      assert_equal "Anonymous", nameless_entry["displayName"]
    end
  end

  test "GET /supporters/progress works without an active goal" do
    assert_api_response :get, 200 do
      assert_nil parsed_body["goal"]
      assert_equal 0, parsed_body["monthlyTotal"]["amountCents"]
      assert_equal [], parsed_body["contributions"]
    end
  end

  test "GET /supporters/progress counts recurring contributions in subsequent months" do
    today = Date.current
    create(:supporter_contribution, :recurring, name: "Carla", amount_cents: 2_500, started_at: 90.days.ago.to_date)

    travel_to today.next_month do
      assert_api_response :get, 200 do
        assert_equal 2_500, parsed_body["monthlyTotal"]["amountCents"]
        assert_equal 1, parsed_body["contributions"].count
      end
    end
  end
end
