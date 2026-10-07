# frozen_string_literal: true

module Discord
  # Applies the join roles one Discord user holds, in one guild or in every
  # guild a fleet has a join role in. The roles are read from Discord rather
  # than from whatever triggered this.
  class ApplyJoinRolesJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    def perform(discord_uid, guild_id = nil)
      return unless ApiClient.configured?

      users = User.joins(:omniauth_connections)
        .where(omniauth_connections: {provider: OmniauthConnection.providers[:discord], uid: discord_uid})
        .to_a
      return if users.empty?

      JoinRole.for_guild(guild_id || guild_ids).group_by(&:guild_id).each_value do |join_roles|
        JoinRole.apply_current(join_roles, users, discord_uid, api:)
      end
    end

    private def guild_ids
      FleetNotificationSetting.where.not(discord_join_role_id: nil).where.not(discord_guild_id: nil).distinct.pluck(:discord_guild_id)
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
