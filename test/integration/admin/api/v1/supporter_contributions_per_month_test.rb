# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::SupporterContributionsPerMonthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/supporter-contributions/per-month" do
    get("Supporter Contributions Per Month") do
      operationId "supporterContributionsPerMonth"
      tags "SupporterContributions"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: ::Admin::V1::Schemas::Queries::SupporterContributionQuery,
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema ::Admin::V1::Schemas::SupporterContributionMonthlyStats
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

  test "GET /supporter-contributions/per-month returns twelve months of totals against the goal" do
    create(:funding_goal, amount_cents: 9_000, effective_from: 2.years.ago.to_date)
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: 2.months.ago.to_date)
    create(:supporter_contribution, amount_cents: 900, started_at: Date.current)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal "EUR", parsed_body["currency"]
      assert_equal 12, parsed_body["items"].size

      current_month = parsed_body["items"].last

      assert_equal I18n.l(Date.current.beginning_of_month, format: :month_year_short), current_month["label"]
      assert_equal 1_400, current_month["amountCents"]
      assert_equal 2, current_month["count"]
      assert_equal 9_000, current_month["goalAmountCents"]
    end
  end

  test "GET /supporter-contributions/per-month respects ransack filters" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.current)
    create(:supporter_contribution, amount_cents: 900, started_at: Date.current)
    sign_in @user

    assert_api_response :get, 200, params: {q: {"recurringEq" => true}} do
      assert_equal 500, parsed_body["items"].last["amountCents"]
      assert_equal 1, parsed_body["items"].last["count"]
    end
  end

  test "GET /supporter-contributions/per-month returns zeroed months without data" do
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 12, parsed_body["items"].size
      assert(parsed_body["items"].all? { |month| month["amountCents"].zero? && month["count"].zero? })
    end
  end

  test "GET /supporter-contributions/per-month returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /supporter-contributions/per-month returns 403 for admin without access" do
    sign_in create(:admin_user, resource_access: [])

    assert_api_response :get, 403
  end
end
