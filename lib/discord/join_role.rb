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
      FleetNotificationSetting.with_join_role.where(discord_guild_id: guild_id).includes(:fleet)
        .map { |setting| new(setting.fleet, setting:) }
    end

    # Called for every member update in every guild the bot is in, so only a
    # linked player in a guild with a join role costs a job, and only when the
    # roles the event carries differ from what was recorded -- a nickname or
    # an avatar changes nothing. The job reads the roles again regardless.
    def self.member_changed(guild_id, discord_uid, role_ids)
      return if guild_id.blank? || discord_uid.blank?

      join_roles = FleetNotificationSetting.with_join_role.where(discord_guild_id: guild_id).pluck(:fleet_id, :discord_join_role_id)
      return if join_roles.empty?

      user_ids = OmniauthConnection.discord.where(uid: discord_uid).pluck(:user_id)
      return if user_ids.empty?

      held = FleetDiscordRoleHolder.where(fleet_id: join_roles.map(&:first), user_id: user_ids).pluck(:fleet_id, :user_id).to_set
      changed = join_roles.any? do |fleet_id, role_id|
        user_ids.any? { |user_id| held.include?([fleet_id, user_id]) != Array(role_ids).include?(role_id) }
      end
      return unless changed

      ApplyJoinRolesJob.perform_async(discord_uid, guild_id)
    end

    # Reads the roles a member holds now and applies them to every join role
    # given, all in one guild. The read and the write happen under one lock per
    # member, which every path that admits or releases through the role takes,
    # so updates handled at once end on what Discord answered last. Returns
    # false only when asking again later might get an answer.
    def self.apply_current(join_roles, users, discord_uid, api:, quiet: false)
      guild_id = join_roles.first&.guild_id
      return true if guild_id.blank? || users.empty?

      with_member_lock(guild_id, discord_uid) do
        # When Discord was asked, not when this finished: a list of the guild
        # read in between is newer than what this applied.
        read_at = Time.current
        role_ids = member_role_ids(api, guild_id, discord_uid)
        join_roles.each do |join_role|
          users.each { |user| join_role.apply(user, role_ids, quiet:) }
          DiscordMemberRead.record(join_role.fleet, discord_uid, at: read_at)
        end
        true
      rescue ApiClient::Error, Faraday::Error => e
        Rails.logger.warn("[Discord::JoinRole] guild=#{guild_id} user=#{discord_uid}: #{e.message}")
        !retryable?(e)
      end
    end

    # Applies roles from a list of the whole guild read at `read_at`, unless
    # the member was read and applied since -- alone, or by another sweep:
    # then the list is the older answer, and applying it could undo a role
    # just gained or lost.
    def self.apply_listed(join_role, users, discord_uid, role_ids, read_at:, quiet: false)
      with_member_lock(join_role.guild_id, discord_uid) do
        next if DiscordMemberRead.newer_than?(join_role.fleet, discord_uid, read_at)

        users.each { |user| join_role.apply(user, role_ids, quiet:) }
        DiscordMemberRead.record(join_role.fleet, discord_uid, at: read_at)
      end
    end

    def self.with_member_lock(guild_id, discord_uid, timeout_seconds: nil, &)
      ::ActiveRecord::Base.with_advisory_lock("discord-join-roles:#{guild_id}:#{discord_uid}", timeout_seconds:, &)
    end

    # Someone who is not in the guild holds none of its roles. Anything else
    # Discord cannot answer raises -- an unknown or unreachable guild most of
    # all, which says nothing about the member's roles.
    def self.member_role_ids(api, guild_id, discord_uid)
      Array(api.get_guild_member(guild_id, discord_uid)&.dig("roles"))
    rescue ApiClient::Error => e
      raise unless e.status == 404 && e.code == ApiClient::UNKNOWN_MEMBER

      []
    end

    # Worth asking again later: the network, a rate limit or Discord's own
    # trouble. A guild the bot cannot see, or one that is gone, stays so.
    def self.retryable?(error)
      error.is_a?(Faraday::Error) || error.status == 429 || error.status >= 500
    end

    attr_reader :fleet

    def initialize(fleet, api: nil, setting: nil)
      @fleet = fleet
      @api = api
      @setting = setting
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

    # Whether the role's first sweep has read the whole guild.
    def swept?
      setting&.discord_join_role_swept_at.present?
    end

    # What a player asking to join gets: a request, unless they hold the role.
    # Discord is asked, so a role granted a moment ago counts; anything it
    # cannot answer -- not in the guild, the bot removed, an outage, an update
    # for them taking too long -- gets the ordinary request instead.
    def request_or_join(membership)
      user = membership.user
      uid = discord_uid(user) if configured?
      return membership.request! if uid.blank?

      acquired = false
      result = self.class.with_member_lock(guild_id, uid, timeout_seconds: TIMEOUT) do
        acquired = true
        # An update for them may have handled it while this waited.
        next membership.accepted? unless membership.reload.kept? && membership.created?

        read_at = Time.current
        role_ids = current_role_ids(uid)
        DiscordMemberRead.record(fleet, uid, at: read_at) unless role_ids.nil?
        next true if Array(role_ids).include?(role_id) && join_through_role(membership)

        membership.request!
      end
      return result if acquired

      # Without the member lock, the row lock is what orders this against the
      # update that holds it and may be admitting this very membership.
      membership.with_lock { membership.created? ? membership.request! : membership.accepted? }
    end

    private def join_through_role(membership)
      FleetMembership.transaction(requires_new: true) do
        # As in apply: a role picked meanwhile is not the one that was read.
        next false unless still_the_role?

        membership.discord_role_granted = true
        unless membership.join!
          # A join that did not save still owes the player a request.
          membership.discord_role_granted = false
          next false
        end

        FleetDiscordRoleHolder.remember(fleet, membership.user)
        true
      end
    end

    private def current_role_ids(uid)
      self.class.member_role_ids(api, guild_id, uid)
    rescue ApiClient::Error, Faraday::Error => e
      Rails.logger.warn("[Discord::JoinRole] guild=#{guild_id} user=#{uid}: #{e.message}")
      nil
    end

    # Applies the roles a player holds now. Nothing happens unless that differs
    # from what was recorded the last time. `quiet` is for admitting a whole
    # guild at once, where telling the officers about each one would bury them.
    # Until the role has been swept, a player whose membership ended --
    # removed, or left -- is only recorded as holding it: holding it when the
    # role is picked is not gaining it, and only gaining it later brings them
    # back.
    def apply(user, role_ids, quiet: false)
      return unless configured?

      FleetDiscordRoleHolder.transaction(requires_new: true) do
        # Read with the fleet's setting locked, so a role changed meanwhile
        # waits for this to finish, or this sees it changed and leaves the
        # role it was handed alone.
        next unless still_the_role?

        if Array(role_ids).include?(role_id)
          # Not recorded as held unless it took effect -- failing or raising --
          # so the next update tries again rather than finding nothing changed.
          next unless FleetDiscordRoleHolder.remember(fleet, user)
          next if !swept? && left?(user)

          raise ActiveRecord::Rollback unless admit(user, quiet:)
        elsif FleetDiscordRoleHolder.forget(fleet, user)
          release(user)
        end
      end
    end

    private def still_the_role?
      FleetNotificationSetting.where(fleet_id: fleet.id, discord_guild_id: guild_id, discord_join_role_id: role_id).lock("FOR SHARE").exists?
    end

    # Whether to record the role as held: it took effect, or it has nothing
    # to do for this player.
    private def admit(user, quiet:)
      membership = fleet.fleet_memberships.kept.find_by(user:)

      case membership&.aasm_state
      when nil
        # Not through the fleet's association, which would keep every
        # admission of a sweep in memory, and a failed one with them.
        join(FleetMembership.new(fleet:, user:, fleet_role: fleet.default_member_role), quiet:)
      when "created"
        # Asking to join stands aside once it sees this, so the membership is
        # either abandoned or the role's to finish. The row lock covers asking
        # to join that gave up waiting for the member lock.
        membership.with_lock { membership.created? && join(membership, quiet:) }
      when "requested"
        membership.quiet = quiet
        membership.answer_request(accept: true) == :done && membership.update!(discord_role_granted: true)
      when "invited"
        # An officer chose them, so the role is not what keeps them in.
        membership.quiet = quiet
        membership.accept_invitation!
      else
        # Already a member, or declined: an officer turned them down, and the
        # role does not overrule that.
        true
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

    private def left?(user)
      memberships = fleet.fleet_memberships.where(user:)
      memberships.discarded.exists? && !memberships.kept.exists?
    end

    # Discarded like a member leaving, so the record of who was in stays.
    private def release(user)
      fleet.fleet_memberships.kept.accepted.find_by(user:, discord_role_granted: true)&.discard
    end

    private def discord_uid(user)
      user.omniauth_connections.discord.pick(:uid)
    end

    private def setting
      @setting ||= fleet.fleet_notification_setting
    end

    private def api
      @api ||= ApiClient.new(timeout: TIMEOUT)
    end
  end
end
