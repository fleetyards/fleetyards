# frozen_string_literal: true

module Announcements
  # Dispatches one announcement to every channel it asked for.
  #
  # Dispatch only: each channel reports its own outcome into its
  # AnnouncementDelivery row, because they fail independently -- X can be rate
  # limited in the same minute Bluesky accepts the post -- and a single status
  # on the announcement has no way to say so.
  class PublishJob < Announcements::BaseJob
    def perform(announcement_id)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?
      return unless announcement.publishable?

      announcement.update!(status: :publishing)

      announcement.social_channels.each do |channel|
        announcement.delivery_for(channel).tap do |delivery|
          delivery.status = :pending
          delivery.save!
        end

        Announcements::PostSocialJob.perform_async(announcement.id, channel.to_s)
      end

      if announcement.notify_users?
        announcement.delivery_for(AnnouncementDelivery::IN_APP_CHANNEL).tap do |delivery|
          delivery.status = :pending
          delivery.save!
        end

        Announcements::FanOutJob.perform_async(announcement.id)
      end

      # Published once every channel has been handed its work, not once every
      # reader has a row: the fan-out is ~58 jobs deep and the admin needs the
      # announcement to stop looking sendable the moment it was sent.
      announcement.update!(status: :published, published_at: Time.current)
    rescue => e
      announcement&.update(status: :failed)
      raise e
    end
  end
end
