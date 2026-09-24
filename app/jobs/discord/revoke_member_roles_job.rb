# frozen_string_literal: true

require "discord/member_role_sync"

module Discord
  # Takes the managed roles off a Discord account that is no longer linked to
  # a member of these fleets -- after an unlink, or after the account was
  # deleted. Neither the connection nor the user may still exist, so the uid
  # and the fleets are captured before they go and handed in.
  #
  # Roles another member linked to the same Discord account is still owed are
  # kept; MemberRoleSync works that out per fleet.
  class RevokeMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(discord_uid, fleet_ids)
      return unless ApiClient.configured?
      return if discord_uid.blank? || fleet_ids.blank?

      linked_before = linked_user_ids(discord_uid)

      Fleet.where(id: fleet_ids).includes(:fleet_notification_setting).find_each do |fleet|
        next if fleet.fleet_notification_setting&.discord_guild_id.blank?

        revoke(fleet, discord_uid)
      end

      # Someone who linked this account while the revoke ran may have lost
      # roles they were owed, so the backfill gets the last word.
      (linked_user_ids(discord_uid) - linked_before).each do |user_id|
        BackfillUserMemberRolesJob.perform_async(user_id)
      end
    end

    private def linked_user_ids(discord_uid)
      OmniauthConnection.discord.where(uid: discord_uid).pluck(:user_id)
    end

    private def revoke(fleet, discord_uid)
      sync = MemberRoleSync.new(fleet: fleet, discord_uid: discord_uid)
      return unless sync.runnable?

      result = sync.run!
      return if result.removed.blank?

      Rails.logger.info("[Discord::RevokeMemberRolesJob] fleet=#{fleet.id} #{result}")
    rescue ApiClient::Error => e
      Rails.logger.error("[Discord::RevokeMemberRolesJob] fleet=#{fleet.id} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end
  end
end
