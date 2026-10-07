# frozen_string_literal: true

require "openapi_helper"

class Admin::Api::V1::DashboardTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"admin/v1/schema"

  api_path "/dashboard" do
    get("Dashboard") do
      operationId "dashboard"
      tags "Dashboard"
      produces "application/json"

      response(200, "successful") do
        schema ::Admin::V1::Schemas::Dashboard
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /dashboard returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /dashboard returns the figures a super admin may see" do
    sign_in create(:admin_user, super_admin: true)

    assert_api_response :get, 200

    body = response.parsed_body

    assert body.key?("unlistedModelsCount")
    assert body.key?("failedImportsCount")
    assert body.key?("stuckImportsCount")
    assert body.key?("unresolvedRsiRequestLogsCount")
    assert body.key?("onlineCount")
    assert body.key?("visitsToday")
    assert body.key?("signupsThisWeek")
  end

  # The point of the endpoint: an admin who cannot open /imports/ is not shown a
  # zero for failed imports, because a zero reads as "nothing is wrong".
  test "GET /dashboard omits the figures the admin has no privilege for" do
    sign_in create(:admin_user, resource_access: [:models])

    assert_api_response :get, 200

    body = response.parsed_body

    assert body.key?("unlistedModelsCount")
    refute body.key?("failedImportsCount")
    refute body.key?("stuckImportsCount")
    refute body.key?("unresolvedRsiRequestLogsCount")
    refute body.key?("onlineCount")
    refute body.key?("visitsToday")
  end

  test "GET /dashboard counts only undecided unlisted models" do
    create(:sc_data_unlisted_model)
    create(:sc_data_unlisted_model, decision: "ignored")

    sign_in create(:admin_user, resource_access: [:models])

    assert_api_response :get, 200

    assert_equal 1, response.parsed_body["unlistedModelsCount"]
  end

  test "GET /dashboard counts a recent failure but not an old one" do
    create(:import, aasm_state: "failed", failed_at: 1.hour.ago)
    create(:import, aasm_state: "failed", failed_at: 3.days.ago)

    sign_in create(:admin_user, resource_access: [:imports])

    assert_api_response :get, 200

    assert_equal 1, response.parsed_body["failedImportsCount"]
  end

  test "GET /dashboard counts a long-running import as stuck, a fresh one not" do
    create(:import, aasm_state: "started", started_at: 5.hours.ago)
    create(:import, aasm_state: "started", started_at: 2.minutes.ago)

    sign_in create(:admin_user, resource_access: [:imports])

    assert_api_response :get, 200

    assert_equal 1, response.parsed_body["stuckImportsCount"]
  end

  # A half-finished period against a whole one starts every day near -100%.
  test "GET /dashboard cuts last week's baselines at the same point in time" do
    travel_to Time.zone.local(2026, 10, 7, 12, 0) do
      last_wednesday = Time.zone.local(2026, 9, 30)

      [10, 14].each do |hour|
        Ahoy::Visit.create!(
          visit_token: SecureRandom.hex,
          visitor_token: SecureRandom.hex,
          started_at: last_wednesday.change(hour:)
        )
      end

      create(:user, created_at: Time.zone.local(2026, 9, 29, 9, 0))
      create(:user, created_at: Time.zone.local(2026, 10, 2, 9, 0))
      create(:user, created_at: Time.zone.local(2026, 10, 6, 9, 0))

      sign_in create(:admin_user, super_admin: true)

      assert_api_response :get, 200

      body = response.parsed_body

      assert_equal 1, body["visitsSameWeekdayLastWeek"]
      assert_equal 1, body["signupsThisWeek"]
      assert_equal 1, body["signupsLastWeek"]
    end
  end
end
