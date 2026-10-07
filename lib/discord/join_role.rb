# frozen_string_literal: true

require "discord/api_client"

module Discord
  # A fleet's join role: a role in its bound guild whose holders are members
  # without anyone answering a request. Discord is trusted for nothing beyond
  # which roles a member holds.
  #
  # Membership follows the role changing, not the role being held. Gaining it
  # admits the player and losing it -- leaving the guild included -- ends a
  # membership the role created. A membership an officer approved or invited is
  # never ended by Discord.
  class JoinRole
    # Seconds per attempt while a player waits on an invite link.
    TIMEOUT = 3

    def self.for_guild(guild_id)
      FleetNotificationSetting
        .where(discord_guild_id: guild_id)
        .where.not(discord_join_role_id: nil)
        .includes(:fleet)
        .map { |setting| new(setting.fleet) }
    end

    # Called for every member update in every guild the bot is in, so only a
    # linked player in a guild with a join role costs a job.
    def self.member_changed(guild_id, discord_uid)
      return if guild_id.blank? || discord_uid.blank?
      return unless FleetNotificationSetting.where(discord_guild_id: guild_id).where.not(discord_join_role_id: nil).exists?
      return unless OmniauthConnection.discord.exists?(uid: discord_uid)

      ApplyJoinRolesJob.perform_async(discord_uid, guild_id)
    end

    attr_reader :fleet

    def initialize(fleet, api: nil)
      @fleet = fleet
      @api = api
    end

    def role_id
      setting&.discord_join_role_id
    end

    def guild_id
      setting&.discord_guild_id
    end

    def configured?
      role_id.present? && guild_id.present? && ApiClient.configured?
    end

    # Asks Discord, so a role granted a moment ago counts. Anything Discord
    # cannot answer -- not in the guild, the bot removed, an outage -- reads as
    # not holding it, and the player gets the ordinary request instead.
    def held_by?(user)
      return false unless configured?

      uid = discord_uid(user)
      return false if uid.blank?

      Array(api.get_guild_member(guild_id, uid)&.dig("roles")).include?(role_id)
    rescue ApiClient::Error, Faraday::Error
      false
    end

    # Applies the roles a player holds now. Nothing happens unless that differs
    # from what was recorded the last time. `quiet` is for admitting a whole
    # guild at once, where telling the officers about each one would bury them.
    def apply(user, role_ids, quiet: false)
      return unless configured?

      if Array(role_ids).include?(role_id)
        return unless FleetDiscordRoleHolder.remember(fleet, user)

        # Not recorded as held unless it took effect, so the next update tries
        # again rather than finding nothing changed.
        FleetDiscordRoleHolder.forget(fleet, user) unless admit(user, quiet:)
      elsif FleetDiscordRoleHolder.forget(fleet, user)
        release(user)
      end
    end

    # Whether the player is now where the role puts them.
    private def admit(user, quiet:)
      membership = fleet.fleet_memberships.kept.find_by(user:)

      case membership&.aasm_state
      when nil
        membership = fleet.fleet_memberships.new(user:, fleet_role: fleet.default_member_role, discord_role_granted: true)
        membership.quiet = quiet
        membership.save_without_conflict && membership.join!
      when "requested"
        membership.answer_request(accept: true) == :done && membership.update!(discord_role_granted: true)
      when "invited"
        # An officer chose them, so the role is not what keeps them in.
        membership.accept_invitation!
      when "created"
        # Mid-way through asking to join, which checks the role itself.
        false
      else
        true
      end
    end

    # Discarded like a member leaving, so the record of who was in stays.
    private def release(user)
      fleet.fleet_memberships.kept.accepted.find_by(user:, discord_role_granted: true)&.discard
    end

    private def discord_uid(user)
      user.omniauth_connections.discord.pick(:uid)
    end

    private def setting
      fleet.fleet_notification_setting
    end

    private def api
      @api ||= ApiClient.new(timeout: TIMEOUT)
    end
  end
end
