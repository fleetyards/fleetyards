# frozen_string_literal: true

module Discord
  # Brings one Discord account's roles in a fleet's guild in line with the
  # Fleetyards memberships linked to it.
  #
  # The invariant that matters: **only role ids the fleet configured are ever
  # touched.** `managed_role_ids` is the whole universe this class may add or
  # remove, so a role the fleet hands out by hand in Discord -- a colour, a
  # game, a moderator role -- is never taken away by us. Anything outside that
  # set is invisible to this code.
  class MemberRoleSync
    Result = Struct.new(:added, :removed, :code) do
      def ok?
        code.nil? || code == :ok
      end

      def to_s
        "added=#{Array(added).size} removed=#{Array(removed).size} code=#{code}"
      end
    end

    # Pass `fleet:` and `discord_uid:` instead of a membership for an account
    # that is no longer linked, whose user can no longer name it.
    def initialize(membership = nil, fleet: nil, discord_uid: nil, api: nil)
      @membership = membership
      @fleet = fleet || membership&.fleet
      @discord_uid = discord_uid.presence
      @api = api
    end

    def runnable?
      ApiClient.configured? && guild_id.present? && discord_uid.present? && managed_role_ids.any?
    end

    def run!
      return Result.new([], [], :not_runnable) unless runnable?

      current = current_role_ids
      return Result.new([], [], :not_in_guild) if current.nil?

      to_add = desired_role_ids - current
      to_remove = (managed_role_ids - desired_role_ids) & current

      to_add.each { |role_id| api.add_guild_member_role(guild_id, discord_uid, role_id) }
      to_remove.each { |role_id| api.remove_guild_member_role(guild_id, discord_uid, role_id) }

      Result.new(to_add, to_remove, :ok)
    rescue ApiClient::Error => e
      # 403 here is almost always the old install mask: the bot has no Manage
      # Roles, or the target role sits above its own highest role. Neither is
      # fixed by retrying, and RoleCapability is what explains it to the fleet.
      raise unless [403, 404].include?(e.status)

      Result.new([], [], (e.status == 403) ? :forbidden : :not_found)
    end

    # Every role this fleet has put under our control, whether or not this
    # member should have it.
    def managed_role_ids
      @managed_role_ids ||= (
        [setting&.discord_member_role_id] + fleet.fleet_roles.pluck(:discord_role_id)
      ).compact_blank.uniq
    end

    # An accepted member gets the member role plus the role mapped to their
    # rank. Anyone else -- invited, requested, declined, removed -- gets
    # neither, which is what makes leaving a fleet take the roles away.
    #
    # Nothing stops two users from linking the same Discord account, so what
    # the account is owed is the union over every accepted membership linked
    # to it, not only the one that triggered the sync.
    def desired_role_ids
      owing = fleet.fleet_memberships.kept
        .where(aasm_state: "accepted")
        .where(user_id: OmniauthConnection.discord.where(uid: discord_uid).select(:user_id))
        .includes(:fleet_role)
        .to_a
      return [] if owing.empty?

      ([setting&.discord_member_role_id] + owing.map { |membership| membership.fleet_role&.discord_role_id })
        .compact_blank.uniq
    end

    private def current_role_ids
      member = api.get_guild_member(guild_id, discord_uid)

      Array(member&.dig("roles"))
    rescue ApiClient::Error => e
      # The member is not in the Discord server. Nothing to sync, and not a
      # failure -- plenty of fleet members never join the Discord.
      raise unless e.status == 404

      nil
    end

    attr_reader :fleet
    private :fleet

    private def setting
      fleet&.fleet_notification_setting
    end

    private def guild_id
      setting&.discord_guild_id.presence
    end

    private def discord_uid
      @discord_uid ||= @membership&.user
        &.omniauth_connections
        &.find_by(provider: "discord")
        &.uid
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
