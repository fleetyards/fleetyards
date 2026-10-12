# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetMemberHealthTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/member-health" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Fleet Member Health") do
      operationId "fleetMemberHealth"
      tags "FleetMembers"
      produces "application/json"

      parameter name: "inactiveDays", in: :query, schema: {type: :integer, minimum: 1, default: 30}, required: false,
        description: "Days without activity after which a member counts as inactive"
      parameter name: "sample", in: :query, schema: {type: :integer, minimum: 0, maximum: 5, default: 5}, required: false,
        description: "Rows returned per check; 0 for counts only"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::FleetMemberHealth
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
    @admin = create(:user, last_active_at: 1.hour.ago)
    @gone = create(:user, last_active_at: 90.days.ago)
    @away = create(:user, last_active_at: 40.days.ago)
    @never = create(:user)
    @never.update_columns(last_active_at: nil)
    @recent = create(:user, last_active_at: 10.days.ago)
    @officer = create(:user, last_active_at: 50.days.ago)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer], members: [@gone, @away, @never, @recent])
  end

  def health
    parsed_body
  end

  test "GET health lists inactive members, officers first, then longest gone" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      inactive = health["inactiveMembers"]

      assert_equal 30, health["inactiveDays"]
      assert_equal 4, inactive["totalCount"]
      assert_equal [@officer, @never, @gone, @away].map(&:username), inactive["items"].pluck("username")
      assert_equal [true, false, false, false], inactive["items"].pluck("leader")
    end
  end

  test "GET health takes the inactive threshold from inactiveDays" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {inactiveDays: 60} do
      assert_equal 60, health["inactiveDays"]
      assert_equal [@never, @gone].map(&:username), health["inactiveMembers"]["items"].pluck("username")
    end
  end

  test "GET health leaves out the RSI org size until the fleet proved the SID" do
    @fleet.update_columns(rsi_sid: "TESTORG", rsi_member_count: 40)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil health["rsiMemberCount"]
    end
  end

  test "GET health returns counts only for sample 0" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}, params: {sample: 0} do
      assert_equal 4, health["inactiveMembers"]["totalCount"]
      assert_empty health["inactiveMembers"]["items"]
    end
  end

  test "GET health counts the admins and offers the rank below for promotion" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, health["admins"]["totalCount"]
      assert_equal [@admin.username], health["admins"]["items"].pluck("username")
      assert_equal [@officer.username], health["admins"]["candidates"].pluck("username")
    end
  end

  test "GET health counts no admins in a fleet without a permanent role" do
    @fleet.fleet_roles.update_all(permanent: false)
    @fleet.fleet_memberships.find_by(user: @recent).update_columns(fleet_role_id: nil)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 0, health["admins"]["totalCount"]
      assert_empty health["admins"]["items"]
    end
  end

  test "GET health offers no admin candidates once there are two admins" do
    @fleet.fleet_memberships.find_by(user: @officer).update_columns(fleet_role_id: @fleet.fleet_roles.find_by(permanent: true).id)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_empty health["admins"]["candidates"]
    end
  end

  test "GET health asks for an RSI handle when the fleet has no SID" do
    @gone.update_columns(rsi_handle: "GoneHandle")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil health["unverifiedMembers"]
      assert_nil health["rsiMemberCount"]
      assert_not_includes health["membersWithoutRsiHandle"]["items"].pluck("username"), @gone.username
    end
  end

  test "GET health says why each member is not verified against the fleet's RSI org" do
    @fleet.update_columns(rsi_sid: "TESTORG", rsi_member_count: 40, rsi_verified_sid: "TESTORG", rsi_verified_at: 1.day.ago)
    @fleet.fleet_memberships.where(user: [@admin, @officer, @never]).update_all(verified: true)
    @gone.update_columns(rsi_handle: nil)
    @away.update_columns(rsi_handle: "AwayHandle", rsi_handle_verified: true, rsi_organizations_checked_at: 3.days.ago)
    @recent.update_columns(rsi_handle: "RecentHandle", rsi_handle_verified: false)
    reminded_at = 2.days.ago.change(usec: 0)
    @fleet.fleet_memberships.find_by(user: @gone).update_columns(verification_reminded_at: reminded_at)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      gaps = health["unverifiedMembers"]["items"].to_h { |item| [item["username"], item["verificationGap"]] }

      assert_equal({@gone.username => "no_handle", @away.username => "org_not_listed", @recent.username => "handle_unverified"}, gaps)
      reminded = health["unverifiedMembers"]["items"].find { |item| item["username"] == @gone.username }
      assert_equal reminded_at.utc.iso8601, reminded["verificationRemindedAt"]
      assert_equal 40, health["rsiMemberCount"]
      assert_equal 6, health["memberCount"]
      assert_nil health["membersWithoutRsiHandle"]
    end
  end

  test "GET health lists join requests and invitations left waiting" do
    old_request = create(:fleet_membership, :requested, fleet: @fleet, requested_at: 10.days.ago)
    create(:fleet_membership, :requested, fleet: @fleet, requested_at: 2.days.ago)
    old_invite = create(:fleet_membership, :invited, fleet: @fleet, invited_at: 20.days.ago, invited_by: @admin.id)
    create(:fleet_membership, :invited, fleet: @fleet, invited_at: 3.days.ago)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 7.days.ago.to_date.iso8601, health["requestedBefore"]
      assert_equal 14.days.ago.to_date.iso8601, health["invitedBefore"]
      assert_equal [old_request.user.username], health["waitingJoinRequests"]["items"].pluck("username")
      invitations = health["unansweredInvitations"]["items"]
      assert_equal [old_invite.user.username], invitations.pluck("username")
      assert_equal @admin.username, invitations.first["invitedBy"]
    end
  end

  test "GET health lists invite links nobody can or does use" do
    expired = create(:fleet_invite_url, :expired, fleet: @fleet, user: @admin, limit: 5)
    used_up = create(:fleet_invite_url, fleet: @fleet, user: @admin, limit: 0, expires_after: 3.days.from_now)
    never_used = create(:fleet_invite_url, :unlimited, fleet: @fleet, user: @admin, created_at: 40.days.ago)
    # In use, unlimited or not, and new enough to have had no chance yet.
    create(:fleet_invite_url, :unlimited, fleet: @fleet, user: @admin, created_at: 40.days.ago, usage_count: 12)
    create(:fleet_invite_url, :unlimited, fleet: @fleet, user: @admin, created_at: 2.days.ago)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [expired, used_up, never_used].map(&:token).sort, health["staleInviteUrls"]["items"].pluck("token").sort
    end
  end

  test "GET health asks for Discord only when the fleet hands out Discord roles" do
    create(:omniauth_connection, user: @gone, provider: :discord)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil health["membersWithoutDiscord"]
    end

    FleetNotificationSetting.create!(fleet: @fleet, discord_guild_id: "123456789012345678", discord_member_role_id: "223456789012345678")

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 5, health["membersWithoutDiscord"]["totalCount"]
    end
  end

  test "GET health lists empty squadrons and members in none when squadrons are on" do
    @fleet.update_columns(squadrons_enabled: true)
    wing = create(:fleet_squadron, fleet: @fleet)
    empty = create(:fleet_squadron, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: wing, fleet_membership: @fleet.fleet_memberships.find_by(user: @admin))
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal [empty.slug], health["emptySquadrons"]["items"].pluck("slug")
      assert_equal 5, health["membersWithoutSquadron"]["totalCount"]
    end
  end

  test "GET health leaves squadrons out when they are off" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil health["emptySquadrons"]
      assert_nil health["membersWithoutSquadron"]
    end
  end

  test "GET health counts members who keep their ships out of the fleet" do
    @fleet.fleet_memberships.find_by(user: @gone).update_columns(ships_filter: FleetMembership.ships_filters[:hide])
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, health["hiddenShipsCount"]
    end
  end

  test "GET health leaves out what the reader may not see" do
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter", resource_access: ["fleet:memberships:read", "fleet:memberships:update"])
    recruiter = create(:user)
    create(:fleet_membership, fleet: @fleet, user: recruiter, fleet_role: role, aasm_state: :accepted)
    @fleet.update_columns(squadrons_enabled: true)
    sign_in recruiter

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_nil health["staleInviteUrls"]
      assert_nil health["emptySquadrons"]
    end
  end

  test "GET health returns 403 for a member who cannot update members" do
    sign_in @recent

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health returns 403 for a role that updates members without reading them" do
    role = create(:fleet_role, fleet: @fleet, name: "Promoter", resource_access: ["fleet:memberships:update"])
    promoter = create(:user)
    create(:fleet_membership, fleet: @fleet, user: promoter, fleet_role: role, aasm_state: :accepted)
    sign_in promoter

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET health with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
