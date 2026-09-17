# frozen_string_literal: true

module Announcements
  # Picks up announcements whose publish_at has passed.
  #
  # A polled sweep rather than a per-announcement perform_at, because an admin
  # who edits or deletes a scheduled announcement would otherwise leave a job
  # queued that still fires with the old text.
  class PublishScheduledJob < Announcements::BaseJob
    def perform
      Announcement.due.pluck(:id).each do |id|
        Announcements::PublishJob.perform_async(id, true)
      end
    end
  end
end
