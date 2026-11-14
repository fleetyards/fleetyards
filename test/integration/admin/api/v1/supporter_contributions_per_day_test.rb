# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsPerDayTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions/per-day" do
    get("Supporter Contributions Per Day") do
      operationId "supporterContributionsPerDay"
      tags "SupporterContributions"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::SupporterContributionQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContributionDailyStats
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
    @user = create(:admin_user, resource_access: [:supporters])
  end

  test "GET /supporter-contributions/per-day returns running totals for this month and the three before" do
    travel_to Date.new(2026, 8, 20) do
      create(:funding_goal, amount_cents: 9_000, effective_from: Date.new(2025, 1, 1))
      create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.new(2026, 6, 5))
      create(:supporter_contribution, amount_cents: 900, started_at: Date.new(2026, 8, 12))
      sign_in @user

      assert_api_response :get, 200 do
        assert_equal "EUR", parsed_body["currency"]
        assert_equal 9_000, parsed_body["goalAmountCents"]
        assert_equal ["May 2026", "June 2026", "July 2026", "August 2026"], parsed_body["items"].pluck("label")
        assert_equal [false, false, false, true], parsed_body["items"].pluck("current")

        current_month = parsed_body["items"].last

        assert_equal 20, current_month["days"].size
        assert_equal 0, current_month["days"][3]
        assert_equal 500, current_month["days"][4]
        assert_equal 1_400, current_month["days"].last
        assert_equal 31, parsed_body["items"].third["days"].size
      end
    end
  end

  test "GET /supporter-contributions/per-day respects ransack filters" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.current.beginning_of_month)
    create(:supporter_contribution, amount_cents: 900, started_at: Date.current.beginning_of_month)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"recurringEq" => true}} do
      assert_equal 500, parsed_body["items"].last["days"].last
    end
  end

  test "GET /supporter-contributions/per-day returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /supporter-contributions/per-day returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
