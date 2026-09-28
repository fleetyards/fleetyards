# frozen_string_literal: true

module Announcements
  # Queues a refresh for every delivery whose counts are due. Runs hourly; how
  # often one delivery is actually refreshed depends on its age, see
  # AnnouncementDelivery#engagement_due?.
  class RefreshEngagementSweepJob < Announcements::BaseJob
    def perform
      now = Time.current

      AnnouncementDelivery.engagement_trackable.find_each do |delivery|
        next unless delivery.engagement_due?(now)

        Announcements::RefreshEngagementJob.perform_async(delivery.id)
      end
    end
  end
end
