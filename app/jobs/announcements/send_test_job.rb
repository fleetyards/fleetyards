# frozen_string_literal: true

require "discord/announcement_preview"

module Announcements
  # The dry run. Posts the announcement, and the copy every other channel would
  # carry, to the admin Discord channel.
  #
  # Nothing else happens: no delivery rows, no status change, no reader touched.
  # That is the whole point -- an announcement cannot be recalled, so the one
  # thing worth having before sending it is a way to look at the real composed
  # output without it going anywhere public.
  class SendTestJob < Announcements::BaseJob
    sidekiq_options retry: false, queue: "notifications"

    def perform(announcement_id)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?
      return unless ::Discord::AnnouncementPreview.configured?

      ::Discord::AnnouncementPreview.new(announcement:).run

      # rubocop:disable Rails/SkipsModelValidations
      announcement.update_column(:last_tested_at, Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
