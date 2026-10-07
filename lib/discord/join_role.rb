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
    # Seconds a player asking to join waits on Discord, and on an update for
    # them that is already asking it.
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

    # Reads the roles a member holds now and applies them to every join role
    # given, all in one guild. The read and the write happen under one lock per
    # member, which every path that admits or releases through the role takes,
    # so updates handled at once end on what Discord answered last.
    def self.apply_current(join_roles, users, discord_uid, api:, quiet: false)
      guild_id = join_roles.first&.guild_id
      return if guild_id.blank? || users.empty?

      with_member_lock(guild_id, discord_uid) do
        role_ids = member_role_ids(api, guild_id, discord_uid)
        next if role_ids.nil?

        join_roles.product(users).each { |join_role, user| join_role.apply(user, role_ids, quiet:) }
      end
    end

    def self.with_member_lock(guild_id, discord_uid, timeout_seconds: nil, &)
      ::ActiveRecord::Base.with_advisory_lock("discord-join-roles:#{guild_id}:#{discord_uid}", timeout_seconds:, &)
    end

    # Someone who is not in the guild holds none of its roles. Anything else
    # Discord cannot answer is no answer at all, and returns nil.
    def self.member_role_ids(api, guild_id, discord_uid)
      Array(api.get_guild_member(guild_id, discord_uid)&.dig("roles"))
    rescue ApiClient::Error => e
      return [] if e.status == 404

      Rails.logger.warn("[Discord::JoinRole] guild=#{guild_id} user=#{discord_uid}: #{e.message}")
      nil
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

    # What a player asking to join gets: a request, unless they hold the role.
    # Discord is asked, so a role granted a moment ago counts; anything it
    # cannot answer -- not in the guild, the bot removed, an outage, an update
    # for them taking too long -- gets the ordinary request instead.
    def request_or_join(membership)
      user = membership.user
      uid = discord_uid(user) if configured?
      return membership.request! if uid.blank?

      locked = self.class.with_member_lock(guild_id, uid, timeout_seconds: TIMEOUT) do
        # An update for them may have handled it while this waited.
        next membership.accepted? unless membership.reload.kept? && membership.created?

        if holds_role?(uid)
          membership.discord_role_granted = true
          membership.join!.tap { |joined| FleetDiscordRoleHolder.remember(fleet, user) if joined }
        else
          membership.request!
        end
      end

      locked || (membership.reload.created? && membership.request!)
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

    private def holds_role?(uid)
      Array(self.class.member_role_ids(api, guild_id, uid)).include?(role_id)
    rescue Faraday::Error
      false
    end

    # Whether the player is now where the role puts them.
    private def admit(user, quiet:)
      membership = fleet.fleet_memberships.kept.find_by(user:)

      case membership&.aasm_state
      when nil
        join(fleet.fleet_memberships.new(user:, fleet_role: fleet.default_member_role), quiet:)
      when "created"
        # Asking to join takes the same lock and stands aside once it sees
        # this, so the membership is either abandoned or the role's to finish.
        join(membership, quiet:)
      when "requested"
        membership.answer_request(accept: true) == :done && membership.update!(discord_role_granted: true)
      when "invited"
        # An officer chose them, so the role is not what keeps them in.
        membership.accept_invitation!
      when "accepted"
        true
      else
        # An officer turned them down, and the role does not overrule that.
        false
      end
    end

    # All or nothing, so a failed join leaves no membership behind to block
    # the next update.
    private def join(membership, quiet:)
      membership.discord_role_granted = true
      membership.quiet = quiet

      joined = false
      FleetMembership.transaction(requires_new: true) do
        joined = membership.save_without_conflict && membership.join!
        raise ActiveRecord::Rollback unless joined
      end
      joined
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
