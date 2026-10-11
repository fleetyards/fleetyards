# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMembersRemindVerificationTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/members/{username}/verification-reminder" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username"

    post("Remind Member to Verify") do
      operationId "remindFleetMemberVerification"
      description "Notifies the member what keeps them from being verified against the fleet's RSI org. Once a week at most."
      tags "FleetMembers"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "reminder sent")

      response(400, "nothing to verify, or reminded within the week") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @member.update_columns(rsi_handle: nil)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @fleet.update_columns(rsi_sid: "TESTORG")
    @membership = @fleet.fleet_memberships.find_by(user: @member)
  end

  def reminders
    Notification.where(user: @member, notification_type: "fleet_verification_requested")
  end

  test "POST verification-reminder tells the member what to fix" do
    sign_in @admin

    assert_api_response :post, 204, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}

    reminder = reminders.sole
    assert_equal @membership, reminder.record
    assert_includes reminder.body, "TESTORG"
    assert_includes reminder.body, "no RSI handle"
  end

  test "POST verification-reminder sends once a week at most" do
    sign_in @admin

    assert_api_response :post, 204, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}

    travel 8.days do
      sign_in @admin
      assert_api_response :post, 204, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
    end
    assert_equal 2, reminders.count
  end

  test "POST verification-reminder refuses a member with nothing to verify" do
    @membership.update_columns(verified: true)
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
    assert_empty reminders
  end

  test "POST verification-reminder refuses a fleet without an RSI SID" do
    @fleet.update_columns(rsi_sid: nil)
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end

  test "POST verification-reminder returns 403 for a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug, username: @admin.username}, body: {}
  end

  test "POST verification-reminder returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug, username: @member.username}, body: {}
  end
end
