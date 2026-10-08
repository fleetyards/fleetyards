# frozen_string_literal: true

module Discord
  class SyncJoinRolesDispatchJob < ::ApplicationJob
    sidekiq_options retry: 0, queue: "notifications"

    def perform
      return unless ApiClient.configured?

      FleetNotificationSetting.with_join_role
        .pluck(:fleet_id)
        .each_with_index { |fleet_id, index| SyncFleetJoinRoleJob.perform_in(index.minutes, fleet_id) }
    end
  end
end
