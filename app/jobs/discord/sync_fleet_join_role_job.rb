# frozen_string_literal: true

module Discord
  # Applies a fleet's join role to everyone in its guild at once: when the role
  # is picked, the players already holding it become members, and once a day it
  # catches the changes the Gateway listener missed while it was down.
  class SyncFleetJoinRoleJob < ::ApplicationJob
    sidekiq_options retry: 1, queue: "notifications"

    def perform(fleet_id)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?

      join_role = JoinRole.new(fleet)
      return unless join_role.configured?

      # Admitting everyone who already holds a newly picked role would bury
      # the officers in notifications, and each member's view in a refresh per
      # admission; anyone a later run admits is news.
      @quiet = !join_role.swept?
      started_at = Time.current

      begin
        seen = apply_guild_members(join_role)
        return if seen.nil?

        # Held now, not when the sweep started: an update may have recorded
        # someone since. Someone who unlinked Discord is not seen either, but
        # nothing says they lost the role.
        gone = OmniauthConnection.discord
          .where(user_id: fleet.fleet_discord_role_holders.where.not(user_id: seen.to_a).select(:user_id))
          .includes(:user)
          .group_by(&:uid)
        gone.each do |uid, connections|
          JoinRole.apply_listed(join_role, connections.map(&:user), uid, [], read_at: started_at, quiet: @quiet)
        end

        # Only for the role it read: one picked meanwhile gets its own sweep.
        FleetNotificationSetting.where(fleet_id: fleet.id, discord_join_role_id: join_role.role_id)
          .update_all(discord_join_role_swept_at: Time.current)
      ensure
        # One refresh of every member's views for the whole quiet sweep --
        # also when it stopped partway, after admitting some.
        fleet.fleet_memberships.kept.accepted.where(discord_role_granted: true).order(:accepted_at).last&.broadcast_sweep_refresh if @quiet
      end
    end

    # Returns the ids of the linked users found in the guild, or nil when the
    # guild could not be read to the end -- a partial list must not read as
    # everyone else having left. What a retry might read raises, so Sidekiq
    # tries again instead of the next daily run.
    private def apply_guild_members(join_role)
      seen = Set.new
      after = nil

      loop do
        read_at = Time.current
        page = api.list_guild_members(join_role.guild_id, after:)
        break if page.blank?

        roles_by_uid = page.to_h { |member| [member.dig("user", "id"), Array(member["roles"])] }

        # Every linked member, not only those whose role looks changed against
        # a snapshot an update may have overtaken: under the member's lock,
        # applying what is already recorded changes nothing.
        OmniauthConnection.discord_users(roles_by_uid.keys).each do |uid, users|
          seen.merge(users.map(&:id))
          JoinRole.apply_listed(join_role, users, uid, roles_by_uid[uid], read_at:, quiet: @quiet)
        end

        break if page.size < ApiClient::MEMBER_PAGE_SIZE

        after = page.last.dig("user", "id")
      end

      seen
    rescue ApiClient::Error, Faraday::Error => e
      raise if JoinRole.retryable?(e)

      Rails.logger.warn("[Discord::SyncFleetJoinRoleJob] fleet=#{join_role.fleet.id}: #{e.message}")
      nil
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
