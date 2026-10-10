# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarRsiPageReportsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/rsi-page-reports" do
    post("Report an RSI Page the Sync Does Not Recognise") do
      operationId "reportRsiPage"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::RsiPageReportInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "reported") do
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    AdminNotificationsChannel.stubs(:broadcast_to)
    @admin_user = create(:admin_user, resource_access: [:"rsi-api-status"])
    @user = create(:user)
  end

  def notifications
    AdminNotification.where(admin_user: @admin_user, notification_type: "rsi_markup_changed")
  end

  test "POST /hangar/rsi-page-reports tells the admins which page and check failed" do
    sign_in @user

    assert_api_response :post, 204,
      body: {page: "hangar", check: "missing_list", pageNumber: 3, extensionVersion: "1.3.0"} do
      notification = notifications.sole
      assert_equal "error", notification.severity
      assert_includes notification.title, "hangar"
      assert_includes notification.body, "missing_list"
      assert_includes notification.body, "Latest page: 3"
      assert_includes notification.body, "1.3.0"
    end
  end

  test "POST /hangar/rsi-page-reports lists what the parser tripped on" do
    sign_in @user

    assert_api_response :post, 204,
      body: {page: "hangar", check: "missing_kinds", details: ['item without kind, liner "", in a "Package" pledge']} do
      assert_includes notifications.sole.body, "- Details:\n  - `item without kind, liner \"\", in a \"Package\" pledge`"
    end
  end

  test "POST /hangar/rsi-page-reports refuses a detail that would break out of its code span" do
    sign_in @user

    assert_api_response :post, 400,
      body: {page: "hangar", check: "missing_kinds", details: ["`[x](https://x.test)`"]}

    assert_empty notifications
  end

  test "POST /hangar/rsi-page-reports counts repeats of the same failure on one notification" do
    sign_in @user

    2.times { post "/api/v1/hangar/rsi-page-reports", params: {page: "buyback", check: "missing_entries"}, as: :json }

    assert_equal 1, notifications.count
    assert_equal 2, notifications.sole.occurrences
  end

  test "POST /hangar/rsi-page-reports keeps the details of earlier repeats" do
    sign_in @user

    [["markup a", "markup b"], ["markup b", "markup c"]].each do |details|
      post "/api/v1/hangar/rsi-page-reports", params: {page: "buyback", check: "unparsed_entries", details:}, as: :json
    end

    assert_includes notifications.sole.body, "- Details:\n  - `markup a`\n  - `markup b`\n  - `markup c`"
  end

  test "POST /hangar/rsi-page-reports keeps only the newest details of many repeats" do
    sign_in @user

    4.times do |run|
      details = Array.new(10) { |index| "markup #{run}-#{index}" }
      post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_kinds", details:}, as: :json
    end

    body = notifications.sole.body
    assert_equal RsiPageReport::MAX_DETAILS, body.scan(/^  - `/).size
    assert_not_includes body, "markup 0-"
    assert_includes body, "markup 3-9"
  end

  test "POST /hangar/rsi-page-reports keeps a detail spanning several lines inside its code span" do
    sign_in @user

    post "/api/v1/hangar/rsi-page-reports",
      params: {page: "hangar", check: "missing_kinds", extensionVersion: "1.0\n[y](https://y.test)", details: ["ok\n`[x](https://x.test)`"]},
      as: :json

    body = notifications.sole.body
    assert_includes body, "  - `ok [x](https://x.test)`"
    assert_not_includes body, "y.test"
  end

  test "POST /hangar/rsi-page-reports names the page and extension of each detail" do
    sign_in @user

    [[3, "1.2.0", "markup a"], [1, "1.3.0", "markup b"]].each do |page_number, extension_version, detail|
      post "/api/v1/hangar/rsi-page-reports",
        params: {page: "buyback", check: "unparsed_entries", pageNumber: page_number, extensionVersion: extension_version, details: [detail]},
        as: :json
    end

    body = notifications.sole.body
    assert_includes body, "  - `markup a` (page 3, extension `1.2.0`)\n  - `markup b` (page 1, extension `1.3.0`)"
    assert_includes body, "- Latest page: 1"
  end

  test "POST /hangar/rsi-page-reports keeps the latest page and extension of a report that sent them" do
    sign_in @user

    post "/api/v1/hangar/rsi-page-reports",
      params: {page: "hangar", check: "missing_kinds", pageNumber: 3, extensionVersion: "1.3.0", details: ["markup a"]},
      as: :json
    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_kinds", details: ["markup b"]}, as: :json

    body = notifications.sole.body
    assert_includes body, "- Latest page: 3\n- Latest extension: `1.3.0`"
    assert_includes body, "  - `markup b`"
  end

  test "POST /hangar/rsi-page-reports counts a user once per page and check" do
    previous_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    sign_in @user
    2.times { post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_list"}, as: :json }
    sign_in create(:user)
    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_list"}, as: :json

    assert_response :no_content
    assert_equal 2, notifications.sole.occurrences
  ensure
    Rails.cache = previous_store
  end

  test "POST /hangar/rsi-page-reports refuses an extension version that is not one" do
    sign_in @user

    assert_api_response :post, 400,
      body: {page: "hangar", check: "missing_list", extensionVersion: "[x](https://x.test)"}

    assert_empty notifications
  end

  test "POST /hangar/rsi-page-reports keeps different failures apart" do
    sign_in @user

    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_list"}, as: :json
    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_kinds"}, as: :json

    assert_equal 2, notifications.count
  end

  test "POST /hangar/rsi-page-reports refuses a check it does not know" do
    sign_in @user

    assert_api_response :post, 400, body: {page: "hangar", check: "<script>"}

    assert_empty notifications
  end

  test "POST /hangar/rsi-page-reports records the stopped sync with the pledges it could not read" do
    sign_in @user
    markup = ['<li><input class="js-pledge-id" value="101"><div class="title">Cutlass Black</div></li>']

    assert_api_response :post, 204,
      body: {page: "hangar", check: "missing_kinds", pageNumber: 22, details: ["item without kind"], markup:} do
      import = Imports::HangarSync.where(user: @user).sole
      assert import.failed?
      assert_equal markup.first, import.import_data
      assert_equal({"check" => "missing_kinds", "page_number" => 22, "details" => ["item without kind"]}, import.input)
      assert_includes import.info, "page 22"

      notification = notifications.sole
      assert_equal import, notification.record
      assert_equal "/maintenance/imports/#{import.id}", notification.link
      assert_includes notification.body, "(page 22, [import](/maintenance/imports/#{import.id}))"
      assert_not_includes notification.body, "Cutlass"
    end
  end

  test "POST /hangar/rsi-page-reports links each repeat's details to its own import" do
    sign_in @user
    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_kinds", details: ["first"]}, as: :json
    sign_in create(:user)
    post "/api/v1/hangar/rsi-page-reports", params: {page: "hangar", check: "missing_kinds", details: ["second"]}, as: :json

    first, second = Imports::HangarSync.order(:created_at).to_a
    body = notifications.sole.body
    assert_includes body, "`first` ([import](/maintenance/imports/#{first.id}))"
    assert_includes body, "`second` ([import](/maintenance/imports/#{second.id}))"
    assert_equal "/maintenance/imports/#{second.id}", notifications.sole.link
  end

  test "POST /hangar/rsi-page-reports records no import for a buyback page" do
    sign_in @user

    post "/api/v1/hangar/rsi-page-reports", params: {page: "buyback", check: "missing_entries"}, as: :json

    assert_response :no_content
    assert_empty Import.all
    assert_nil notifications.sole.link
  end

  test "POST /hangar/rsi-page-reports refuses more than five pledges of markup" do
    sign_in @user

    assert_api_response :post, 400,
      body: {page: "hangar", check: "missing_kinds", markup: Array.new(6) { "<li></li>" }}

    assert_empty Import.all
  end

  test "POST /hangar/rsi-page-reports returns 401 when not signed in" do
    assert_api_response :post, 401, body: {page: "hangar", check: "missing_list"}
  end
end
