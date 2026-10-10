# frozen_string_literal: true

module Notifications
  # Tells open tabs that notifications of their reader's were deleted, so the
  # inbox and the badge drop them without a reload. Off the request, because
  # a fleet-wide takedown reaches every member.
  class BroadcastWithdrawnJob < Notifications::BaseJob
    # Keyed by user id, each with the ids of that reader's withdrawn
    # notifications.
    def perform(ids_by_user)
      reachable = BulkDelivery.reachable_ids(ids_by_user.keys)
      return if reachable.empty?

      User.where(id: reachable).find_each do |user|
        UserNotificationsChannel.broadcast_to(user, {withdrawnIds: ids_by_user[user.id]})
      rescue => e
        Rails.logger.error("[BroadcastWithdrawnJob] #{user.id} not told: #{e.class}: #{e.message}")
      end
    end
  end
end
