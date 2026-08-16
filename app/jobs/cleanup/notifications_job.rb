# frozen_string_literal: true

module Cleanup
  class NotificationsJob < ::Cleanup::BaseJob
    def perform
      Notification.expired.in_batches(of: 1000).delete_all
    end
  end
end
