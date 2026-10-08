# frozen_string_literal: true

module Discord
  # Applies the join roles one Discord user holds, in one guild or in every
  # guild a fleet has a join role in. The roles are read from Discord rather
  # than from whatever triggered this.
  class ApplyJoinRolesJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    class Unanswered < StandardError; end

    def perform(discord_uid, guild_id = nil)
      return unless ApiClient.configured?

      users = User.joins(:omniauth_connections)
        .where(omniauth_connections: {provider: OmniauthConnection.providers[:discord], uid: discord_uid})
        .to_a
      return if users.empty?

      unanswered = JoinRole.for_guild(guild_id || guild_ids).group_by(&:guild_id).reject do |_guild, join_roles|
        JoinRole.apply_current(join_roles, users, discord_uid, api:)
      end
      # Retried as a whole: applying a guild that did answer again changes
      # nothing.
      raise Unanswered, "guilds #{unanswered.keys.join(", ")} did not answer for #{discord_uid}" if unanswered.any?
    end

    private def guild_ids
      FleetNotificationSetting.with_join_role.distinct.pluck(:discord_guild_id)
    end

    # A single attempt per call: the member lock is held while it waits, and
    # Sidekiq retries without holding anything.
    private def api
      @api ||= ApiClient.new(timeout: JoinRole::TIMEOUT)
    end
  end
end
