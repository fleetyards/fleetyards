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
      @held = fleet.fleet_discord_role_holders.pluck(:user_id).to_set
      started_at = Time.current

      seen = apply_guild_members(join_role)
      return if seen.nil?

      # Someone who unlinked Discord is not seen either, but nothing says they
      # lost the role.
      gone = OmniauthConnection.discord
        .where(user_id: @held - seen)
        .includes(:user)
        .group_by(&:uid)
      gone.each do |uid, connections|
        JoinRole.apply_listed(join_role, connections.map(&:user), uid, [], read_at: started_at, quiet: @quiet)
      end

      # One refresh of every member's view for the whole quiet sweep.
      fleet.fleet_memberships.kept.accepted.where(accepted_at: started_at..).last&.broadcast_to_members if @quiet

      # Only for the role it read: one picked meanwhile gets its own sweep.
      FleetNotificationSetting.where(fleet_id: fleet.id, discord_join_role_id: join_role.role_id)
        .update_all(discord_join_role_swept_at: Time.current)
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

        OmniauthConnection.discord_users(roles_by_uid.keys).each do |uid, users|
          seen.merge(users.map(&:id))
          holds = roles_by_uid[uid].include?(join_role.role_id)
          changed = users.reject { |user| @held.include?(user.id) == holds }
          next if changed.empty?

          JoinRole.apply_listed(join_role, changed, uid, roles_by_uid[uid], read_at:, quiet: @quiet)
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
