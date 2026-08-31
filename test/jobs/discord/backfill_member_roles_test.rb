# frozen_string_literal: true

require "test_helper"

module Discord
  # The rollout case the per-membership sync cannot see: a mapping or an account
  # link is not a membership change, so without a backfill a fleet configures a
  # role and nothing happens.
  class BackfillMemberRolesTest < ActiveSupport::TestCase
    setup do
      ::Discord::ApiClient.stubs(:configured?).returns(true)
      @fleet = create(:fleet)
      @setting = @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
      @role = @fleet.fleet_roles.ranked.last
      clear_jobs
    end

    def clear_jobs
      ::Discord::SyncMemberRolesJob.jobs.clear
      ::Discord::BackfillFleetMemberRolesJob.jobs.clear
      ::Discord::BackfillUserMemberRolesJob.jobs.clear
    end

    def accepted_member(linked: true, role: @role)
      user = create(:user)
      create(:omniauth_connection, user: user, provider: "discord", uid: "uid-#{user.id}") if linked
      membership = @fleet.fleet_memberships.create!(user: user, fleet_role: role)
      membership.update!(aasm_state: "accepted")
      membership
    end

    def synced_membership_ids
      ::Discord::SyncMemberRolesJob.jobs.map { |job| job["args"].first }
    end

    class FromTheFleetJob < BackfillMemberRolesTest
      test "syncs the accepted members who linked Discord" do
        membership = accepted_member
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_equal [membership.id], synced_membership_ids
      end

      # A sync for someone with no linked account is a job that can only decide
      # to do nothing.
      test "skips a member who never linked Discord" do
        accepted_member(linked: false)
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_empty synced_membership_ids
      end

      test "skips a member who has not accepted yet" do
        user = create(:user)
        create(:omniauth_connection, user: user, provider: "discord", uid: "uid-x")
        @fleet.fleet_memberships.create!(user: user, fleet_role: @role)
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_empty synced_membership_ids
      end

      test "skips a discarded membership" do
        membership = accepted_member
        membership.discard
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_empty synced_membership_ids
      end

      test "narrows to one rank when a rank mapping changed" do
        other_role = @fleet.fleet_roles.ranked.first
        wanted = accepted_member(role: @role)
        accepted_member(role: other_role)
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id, @role.id)

        assert_equal [wanted.id], synced_membership_ids
      end

      test "does nothing for a fleet with no Discord server" do
        accepted_member
        @setting.update!(discord_guild_id: nil)
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_empty synced_membership_ids
      end

      test "does nothing without a bot token" do
        accepted_member
        ::Discord::ApiClient.stubs(:configured?).returns(false)
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        assert_empty synced_membership_ids
      end

      # A large fleet is spread rather than fired at Discord at once.
      test "spreads the syncs over time" do
        (::Discord::BackfillFleetMemberRolesJob::PER_SECOND + 2).times { accepted_member }
        clear_jobs

        ::Discord::BackfillFleetMemberRolesJob.new.perform(@fleet.id)

        scheduled = ::Discord::SyncMemberRolesJob.jobs.filter_map { |job| job["at"] }

        assert scheduled.any?, "expected later members to be scheduled rather than immediate"
      end
    end

    class Triggers < BackfillMemberRolesTest
      test "mapping the member role backfills the fleet" do
        @setting.update!(discord_member_role_id: "role-member")

        assert_equal [@fleet.id], ::Discord::BackfillFleetMemberRolesJob.jobs.map { |job| job["args"].first }
      end

      test "an unrelated setting change does not backfill" do
        @setting.update!(discord_channel_id: "channel-1")

        assert_empty ::Discord::BackfillFleetMemberRolesJob.jobs
      end

      test "mapping a rank backfills that rank only" do
        @role.update!(discord_role_id: "role-officer")

        assert_equal [[@fleet.id, @role.id]], ::Discord::BackfillFleetMemberRolesJob.jobs.map { |job| job["args"] }
      end

      test "linking a Discord account backfills that member" do
        user = create(:user)
        clear_jobs

        create(:omniauth_connection, user: user, provider: "discord", uid: "uid-new")

        assert_equal [user.id], ::Discord::BackfillUserMemberRolesJob.jobs.map { |job| job["args"].first }
      end

      test "linking another provider does not backfill" do
        user = create(:user)
        clear_jobs

        create(:omniauth_connection, user: user, provider: "github", uid: "uid-gh")

        assert_empty ::Discord::BackfillUserMemberRolesJob.jobs
      end
    end

    class FromTheUserJob < BackfillMemberRolesTest
      test "syncs every accepted membership the member holds" do
        membership = accepted_member
        clear_jobs

        ::Discord::BackfillUserMemberRolesJob.new.perform(membership.user_id)

        assert_equal [membership.id], synced_membership_ids
      end

      test "skips a fleet that has no Discord server" do
        membership = accepted_member
        @setting.update!(discord_guild_id: nil)
        clear_jobs

        ::Discord::BackfillUserMemberRolesJob.new.perform(membership.user_id)

        assert_empty synced_membership_ids
      end
    end
  end
end
