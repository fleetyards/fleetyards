# frozen_string_literal: true

module Discord
  class SyncJoinRolesDispatchJob < ::ApplicationJob
    sidekiq_options retry: 0, queue: "notifications"

    def perform
      return unless ApiClient.configured?

      FleetNotificationSetting
        .where.not(discord_join_role_id: nil)
        .where.not(discord_guild_id: nil)
        .pluck(:fleet_id)
        .each_with_index { |fleet_id, index| SyncFleetJoinRoleJob.perform_in(index.minutes, fleet_id) }
    end
  end
end
