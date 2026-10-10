# frozen_string_literal: true

module Notifications
  module InApp
    # Hands a posted announcement to the job that tells the fleet. Posting
    # notifies; editing an announcement says nothing, because it is the same
    # news reworded.
    class FleetAnnouncementSubscriber
      EVENT_NAME = "fleet_announcement.posted"

      def self.register!
        ActiveSupport::Notifications.subscribe(EVENT_NAME) do |*args|
          announcement = ActiveSupport::Notifications::Event.new(*args).payload[:announcement]
          Notifications::FleetAnnouncementPostedJob.perform_async(announcement.id) if announcement.present?
        rescue => e
          Rails.logger.error("[FleetAnnouncementSubscriber] #{EVENT_NAME} failed: #{e.class}: #{e.message}")
        end
      end
    end
  end
end
