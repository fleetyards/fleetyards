# frozen_string_literal: true

module Announcements
  # Splits the reader list into batches and hands each one to its own job.
  #
  # Split rather than looped, because the work is ~57k inserts and ~57k
  # broadcasts: one job holding all of it occupies a worker for minutes and
  # loses everything it had done if it dies halfway.
  class FanOutJob < Announcements::BaseJob
    def perform(announcement_id)
      announcement = Announcement.find_by(id: announcement_id)
      return if announcement.blank?

      count = 0

      User.confirmed.in_batches(of: Announcement::FAN_OUT_BATCH_SIZE) do |batch|
        user_ids = batch.pluck(:id)
        count += user_ids.size

        Announcements::NotifyBatchJob.perform_async(announcement.id, user_ids)
      end

      announcement.update!(recipients_count: count)

      # Succeeded once every batch is queued. The batches report their own
      # failures through Sidekiq; a delivery row that waited for all 58 of them
      # would sit pending for as long as the slowest one.
      announcement.delivery_for(AnnouncementDelivery::IN_APP_CHANNEL).succeed!
    end
  end
end
