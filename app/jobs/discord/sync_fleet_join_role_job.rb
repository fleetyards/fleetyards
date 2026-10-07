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

      # Admitting everyone who already holds a newly picked role would bury
      # the officers in notifications; anyone the daily run admits is news.
      @quiet = reset
      @held = fleet.fleet_discord_role_holders.pluck(:user_id).to_set

      seen = apply_guild_members(join_role)
      return if seen.nil?

      # Someone who unlinked Discord is not seen either, but nothing says they
      # lost the role.
      gone = OmniauthConnection.discord
        .where(user_id: @held - seen)
        .includes(:user)
        .group_by(&:uid)
      gone.each { |uid, connections| apply(join_role, uid, connections.map(&:user)) }
    end

    # Returns the ids of the linked users found in the guild, or nil when the
    # guild could not be read to the end -- a partial list must not read as
    # everyone else having left.
    private def apply_guild_members(join_role)
      seen = Set.new
      after = nil

      loop do
        page = api.list_guild_members(join_role.guild_id, after:)
        break if page.blank?

        roles_by_uid = page.to_h { |member| [member.dig("user", "id"), Array(member["roles"])] }

        linked_users(roles_by_uid.keys).each do |uid, users|
          seen.merge(users.map(&:id))
          holds = roles_by_uid[uid].include?(join_role.role_id)
          changed = users.reject { |user| @held.include?(user.id) == holds }
          apply(join_role, uid, changed) if changed.any?
        end

        break if page.size < ApiClient::MEMBER_PAGE_SIZE

        after = page.last.dig("user", "id")
      end

      seen
    rescue ApiClient::Error => e
      Rails.logger.warn("[Discord::SyncFleetJoinRoleJob] fleet=#{join_role.fleet.id}: #{e.message}")
      nil
    end

    # The page is only a hint of who changed: by the time it is applied an
    # update may have handled the member, so their roles are read again.
    private def apply(join_role, uid, users)
      JoinRole.apply_current([join_role], users, uid, api:, quiet: @quiet)
    end

    private def linked_users(uids)
      OmniauthConnection.discord.where(uid: uids).includes(:user).group_by(&:uid).transform_values { |connections| connections.map(&:user) }
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
