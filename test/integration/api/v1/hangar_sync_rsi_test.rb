# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarSyncRsiTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/sync-rsi-hangar" do
    put("Sync RSI Hangar") do
      operationId "syncRsiHangar"
      tags "Hangar"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::SyncRsiHangarInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::HangarSyncSubmitResult
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(400, "bad request") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "PUT /hangar/sync-rsi-hangar submits a sync" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}
    assert_api_response :put, 200, body: body
  end

  test "PUT /hangar/sync-rsi-hangar keeps the pages it read only in part and tells the admins" do
    AdminNotificationsChannel.stubs(:broadcast_to)
    admin_user = create(:admin_user, resource_access: [:"rsi-api-status"])
    user = create(:user)
    sign_in user
    unread_page = {check: "missing_kinds", pageNumber: 3, details: ["item without kind"], markup: ["<li>Cutlass Black</li>"]}

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], extensionVersion: "1.4.0", unreadPages: [unread_page]}
    assert_api_response :put, 200, body: body

    import = Imports::HangarSync.where(user_id: user.id).sole
    assert_equal [{"check" => "missing_kinds", "page_number" => 3, "details" => ["item without kind"], "markup" => ["<li>Cutlass Black</li>"]}],
      import.unread_pages

    notification = AdminNotification.where(admin_user:, notification_type: "rsi_markup_changed").sole
    assert_equal import, notification.record
    assert_includes notification.body, "could not read every item"
    assert_includes notification.body, "`item without kind` (page 3, extension `1.4.0`, [import](/maintenance/imports/#{import.id}))"
    assert_not_includes notification.body, "Cutlass"
  end

  test "PUT /hangar/sync-rsi-hangar queues the sync even when the admins' report fails" do
    user = create(:user)
    sign_in user
    RsiPageReport.stubs(:record!).raises(StandardError, "cache down")
    Appsignal.expects(:report_error).once

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], unreadPages: [{check: "missing_kinds", pageNumber: 1}]}
    assert_difference -> { HangarSyncJob.jobs.size }, 1 do
      put "/api/v1/hangar/sync-rsi-hangar", params: body, as: :json
    end

    assert_response :ok
  end

  test "PUT /hangar/sync-rsi-hangar sends no report for a sync that read every item" do
    AdminNotificationsChannel.stubs(:broadcast_to)
    create(:admin_user, resource_access: [:"rsi-api-status"])
    user = create(:user)
    sign_in user

    put "/api/v1/hangar/sync-rsi-hangar", params: {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}, as: :json

    assert_response :ok
    assert_equal [], Imports::HangarSync.where(user_id: user.id).sole.unread_pages
    assert_empty AdminNotification.where(notification_type: "rsi_markup_changed")
  end

  test "PUT /hangar/sync-rsi-hangar refuses more than five pages read in part" do
    sign_in create(:user)

    body = {items: [], unreadPages: Array.new(6) { |index| {check: "missing_kinds", pageNumber: index + 1} }}
    assert_api_response :put, 400, body: body
  end

  test "PUT /hangar/sync-rsi-hangar records the target group" do
    user = create(:user)
    group = HangarGroup.create!(user_id: user.id, name: "RSI", color: "#ffffff")
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], hangarGroupId: group.id}
    assert_api_response :put, 200, body: body

    assert_equal group.id, Imports::HangarSync.find_by(user_id: user.id).hangar_group_id
  end

  test "PUT /hangar/sync-rsi-hangar records the bundled vehicle choice" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], addBundledVehicles: false}
    assert_api_response :put, 200, body: body

    refute_predicate Imports::HangarSync.find_by(user_id: user.id), :add_bundled_vehicles?
  end

  # Every sync before the option existed created the snub craft a ship comes
  # with, and a client that does not know about the flag keeps doing so.
  test "PUT /hangar/sync-rsi-hangar adds bundled vehicles when the flag is absent" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}
    assert_api_response :put, 200, body: body

    assert_predicate Imports::HangarSync.find_by(user_id: user.id), :add_bundled_vehicles?
  end

  test "PUT /hangar/sync-rsi-hangar records whether to sync paints and hangar flair" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], syncPaints: false, syncHangarFlair: false}
    assert_api_response :put, 200, body: body

    import = Imports::HangarSync.find_by(user_id: user.id)
    refute_predicate import, :sync_paints?
    refute_predicate import, :sync_hangar_flair?
  end

  test "PUT /hangar/sync-rsi-hangar leaves paints and hangar flair alone when the flags are absent" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}
    assert_api_response :put, 200, body: body

    import = Imports::HangarSync.find_by(user_id: user.id)
    refute_predicate import, :sync_paints?
    refute_predicate import, :sync_hangar_flair?
  end

  test "PUT /hangar/sync-rsi-hangar records what to do with the ships it does not find" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], unmatchedVehiclesAction: "delete"}
    assert_api_response :put, 200, body: body

    assert_equal "delete", Imports::HangarSync.find_by(user_id: user.id).unmatched_vehicles_action
  end

  # Every sync before the option existed moved them to the wishlist, and so does
  # a client that does not know about it.
  test "PUT /hangar/sync-rsi-hangar moves them to the wishlist when no action is sent" do
    user = create(:user)
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}
    assert_api_response :put, 200, body: body

    assert_equal "wishlist", Imports::HangarSync.find_by(user_id: user.id).unmatched_vehicles_action
  end

  test "PUT /hangar/sync-rsi-hangar records the group to file them into" do
    user = create(:user)
    group = HangarGroup.create!(user_id: user.id, name: "Sort me out", color: "#ffffff")
    sign_in user

    body = {
      items: [{id: "1", name: "Constellation Andromeda", type: "ship"}],
      unmatchedVehiclesAction: "group",
      unmatchedHangarGroupId: group.id
    }
    assert_api_response :put, 200, body: body

    import = Imports::HangarSync.find_by(user_id: user.id)

    assert_equal "group", import.unmatched_vehicles_action
    assert_equal group.id, import.unmatched_hangar_group_id
  end

  # `group` without a group of its own is not that action, and the import would
  # refuse to save. Leaving the ships alone costs the user nothing they picked;
  # a 400 would cost them the whole scrape.
  test "PUT /hangar/sync-rsi-hangar falls back to keeping them when the group is somebody else's" do
    user = create(:user)
    other = HangarGroup.create!(user_id: create(:user).id, name: "Theirs", color: "#ffffff")
    sign_in user

    body = {
      items: [{id: "1", name: "Constellation Andromeda", type: "ship"}],
      unmatchedVehiclesAction: "group",
      unmatchedHangarGroupId: other.id
    }
    assert_api_response :put, 200, body: body

    import = Imports::HangarSync.find_by(user_id: user.id)

    assert_equal "keep", import.unmatched_vehicles_action
    assert_nil import.unmatched_hangar_group_id
  end

  # The id arrives from the client, so an id belonging to somebody else must not
  # file this user's ships under a group they cannot see.
  test "PUT /hangar/sync-rsi-hangar ignores a group owned by somebody else" do
    user = create(:user)
    other = HangarGroup.create!(user_id: create(:user).id, name: "Theirs", color: "#ffffff")
    sign_in user

    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}], hangarGroupId: other.id}
    assert_api_response :put, 200, body: body

    assert_nil Imports::HangarSync.find_by(user_id: user.id).hangar_group_id
  end

  test "PUT /hangar/sync-rsi-hangar submits an empty list" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 200, body: {items: []}

    assert_equal [], Imports::HangarSync.find_by(user_id: user.id).input
  end

  test "PUT /hangar/sync-rsi-hangar returns 400 for missing body" do
    user = create(:user)
    sign_in user

    assert_api_response :put, 400, body: nil
  end

  test "PUT /hangar/sync-rsi-hangar returns 401 when not signed in" do
    body = {items: [{id: "1", name: "x", type: "ship"}]}
    assert_api_response :put, 401, body: body
  end

  test "PUT /hangar/sync-rsi-hangar with OAuth bearer token" do
    user = create(:user)
    body = {items: [{id: "1", name: "Constellation Andromeda", type: "ship"}]}

    assert_api_response :put, 200,
      headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"]),
      body: body
  end
end
