# frozen_string_literal: true

require "discord/member_role_sync"

module Discord
  # Takes every managed role of every fleet a member belongs to off a Discord
  # account they just unlinked. Once the connection is gone the per-membership
  # sync can no longer find that account, so the uid is handed in.
  class RevokeUserMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(user_id, discord_uid)
      return unless ApiClient.configured?
      return if discord_uid.blank?

      user = User.find_by(id: user_id)
      return if user.blank?
      # Relinked the same account before this ran: the backfill owns it again.
      return if user.omniauth_connections.exists?(provider: "discord", uid: discord_uid)

      user.fleet_memberships.includes(fleet: :fleet_notification_setting).find_each do |membership|
        next if membership.fleet&.fleet_notification_setting&.discord_guild_id.blank?

        sync = MemberRoleSync.new(membership, discord_uid: discord_uid, revoke: true)
        next unless sync.runnable?

        result = sync.run!
        next if result.removed.blank?

        Rails.logger.info("[Discord::RevokeUserMemberRolesJob] membership=#{membership.id} #{result}")
      end
    rescue ApiClient::Error => e
      Rails.logger.error("[Discord::RevokeUserMemberRolesJob] user=#{user_id} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end
  end
end
