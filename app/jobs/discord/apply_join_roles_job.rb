# frozen_string_literal: true

module Discord
  # Applies the join roles one Discord user holds, in one guild or in every
  # guild a fleet has a join role in. The roles are read from Discord rather
  # than from whatever triggered this, so two updates handled out of order
  # still end on the roles the member holds now.
  class ApplyJoinRolesJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    def perform(discord_uid, guild_id = nil)
      return unless ApiClient.configured?

      users = User.joins(:omniauth_connections)
        .where(omniauth_connections: {provider: OmniauthConnection.providers[:discord], uid: discord_uid})
        .to_a
      return if users.empty?

      join_roles = JoinRole.for_guild(guild_id || guild_ids).group_by(&:guild_id)

      join_roles.each do |guild, fleets|
        role_ids = member_role_ids(guild, discord_uid)
        next if role_ids.nil?

        fleets.product(users).each { |join_role, user| join_role.apply(user, role_ids) }
      end
    end

    private def guild_ids
      FleetNotificationSetting.where.not(discord_join_role_id: nil).where.not(discord_guild_id: nil).distinct.pluck(:discord_guild_id)
    end

    # Someone who is not in the guild holds none of its roles. Anything else
    # Discord cannot answer is no answer at all, and changes nothing.
    private def member_role_ids(guild_id, discord_uid)
      Array(api.get_guild_member(guild_id, discord_uid)&.dig("roles"))
    rescue ApiClient::Error => e
      return [] if e.status == 404

      Rails.logger.warn("[Discord::ApplyJoinRolesJob] guild=#{guild_id} user=#{discord_uid}: #{e.message}")
      nil
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
