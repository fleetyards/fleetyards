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
end
