# frozen_string_literal: true

module Discord
  # Applies a fleet's join role to everyone in its guild at once: when the role
  # is picked, the players already holding it become members, and once a day it
  # catches the changes the Gateway listener missed while it was down.
  class SyncFleetJoinRoleJob < ::ApplicationJob
    sidekiq_options retry: 1, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally. `reset`
    # forgets who held the previous role, so the new one is applied as gained
    # by everyone holding it and as lost by nobody -- changing the role keeps
    # the members the old one brought in.
    def perform(fleet_id, reset = false)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?

      fleet.fleet_discord_role_holders.delete_all if reset

      join_role = JoinRole.new(fleet)
      return unless join_role.configured?

      seen = apply_guild_members(join_role)
      return if seen.nil?

      fleet.fleet_discord_role_holders.where.not(user_id: seen).includes(:user).find_each do |holder|
        join_role.apply(holder.user, [])
      end
    end

    # Returns the ids of the linked users found in the guild, or nil when the
    # guild could not be read to the end -- a partial list must not read as
    # everyone else having left.
    private def apply_guild_members(join_role)
      seen = []
      after = nil

      loop do
        page = api.list_guild_members(join_role.guild_id, after:)
        break if page.blank?

        roles_by_uid = page.to_h { |member| [member.dig("user", "id"), Array(member["roles"])] }

        linked_users(roles_by_uid.keys).each do |user, uid|
          seen << user.id
          join_role.apply(user, roles_by_uid[uid])
        end

        break if page.size < ApiClient::MEMBER_PAGE_SIZE

        after = page.last.dig("user", "id")
      end

      seen
    rescue ApiClient::Error => e
      Rails.logger.warn("[Discord::SyncFleetJoinRoleJob] fleet=#{join_role.fleet.id}: #{e.message}")
      nil
    end

    private def linked_users(uids)
      OmniauthConnection.discord.where(uid: uids).includes(:user).map { |connection| [connection.user, connection.uid] }
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
