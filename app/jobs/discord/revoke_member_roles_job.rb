# frozen_string_literal: true

require "discord/member_role_sync"

module Discord
  # Takes the managed roles off a Discord account that is no longer linked to
  # a member of these fleets -- after an unlink, or after the account was
  # deleted. Neither the connection nor the user may still exist, so the uid
  # and the fleets are captured before they go and handed in.
  #
  # Roles still owed to the account -- through another member linked to it, or
  # another fleet on the same Discord server -- are kept; MemberRoleSync works
  # that out.
  #
  # `snapshots` holds `[fleet_id, guild_id, managed_role_ids]` per fleet, for
  # a fleet that was destroyed along with the account and can no longer be
  # read.
  class RevokeMemberRolesJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(discord_uid, fleet_ids, snapshots = [])
      return unless ApiClient.configured?
      return if discord_uid.blank? || fleet_ids.blank?

      linked_before = linked_user_ids(discord_uid)
      fleets = Fleet.where(id: fleet_ids).includes(:fleet_notification_setting).to_a

      fleets.each do |fleet|
        next if fleet.fleet_notification_setting&.discord_guild_id.blank?

        revoke(fleet, discord_uid)
      end

      existing_ids = fleets.map(&:id)
      Array(snapshots).each do |fleet_id, guild_id, role_ids|
        next if existing_ids.include?(fleet_id)

        revoke_destroyed(fleet_id, guild_id, Array(role_ids), discord_uid)
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
      sync = MemberRoleSync.new(fleet: fleet, discord_uid: discord_uid, api: api)
      return unless sync.runnable?

      result = sync.run!
      return if result.removed.blank?

      Rails.logger.info("[Discord::RevokeMemberRolesJob] fleet=#{fleet.id} #{result}")
    rescue ApiClient::Error => e
      log_and_reraise_retryable(fleet.id, e)
    end

    private def revoke_destroyed(fleet_id, guild_id, role_ids, discord_uid)
      return if guild_id.blank? || role_ids.empty?

      removable = role_ids - MemberRoleSync.owed_in_guild(guild_id, discord_uid)
      return if removable.empty?

      current = Array(api.get_guild_member(guild_id, discord_uid)&.dig("roles"))
      (removable & current).each { |role_id| api.remove_guild_member_role(guild_id, discord_uid, role_id) }
    rescue ApiClient::Error => e
      # 404: the account is not in that Discord server any more.
      return if e.status == 404

      log_and_reraise_retryable(fleet_id, e)
    end

    private def log_and_reraise_retryable(fleet_id, error)
      Rails.logger.error("[Discord::RevokeMemberRolesJob] fleet=#{fleet_id} failed: #{error.message}")
      raise error if error.status == 429 || error.status >= 500
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
