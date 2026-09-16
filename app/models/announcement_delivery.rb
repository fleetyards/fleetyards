# frozen_string_literal: true

# == Schema Information
#
# Table name: announcement_deliveries
#
#  id              :uuid             not null, primary key
#  attempts        :integer          default(0), not null
#  channel         :string           not null
#  delivered_at    :datetime
#  error           :text
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :uuid             not null
#  external_id     :string
#
# Indexes
#
#  index_announcement_deliveries_on_announcement_id_and_channel  (announcement_id,channel) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id) ON DELETE => cascade
#
class AnnouncementDelivery < ApplicationRecord
  IN_APP_CHANNEL = :in_app
  # Order matters only for display; the publish job dispatches them in
  # parallel.
  SOCIAL_CHANNELS = %i[discord bluesky x].freeze

  belongs_to :announcement

  enum :channel, {
    in_app: "in_app",
    discord: "discord",
    bluesky: "bluesky",
    x: "x"
  }, prefix: true

  enum :status, {
    pending: "pending",
    succeeded: "succeeded",
    # A channel whose client has no credentials. Distinct from `failed`: there
    # was nothing wrong with the announcement, and a retry changes nothing
    # until somebody adds the keys.
    skipped: "skipped",
    failed: "failed"
  }, prefix: true

  # What a retry is offered on. A succeeded delivery has nothing to repeat and
  # a pending one already has a job doing the work.
  RETRYABLE_STATUSES = %w[failed skipped].freeze

  validates :channel, uniqueness: {scope: :announcement_id}

  def retryable?
    RETRYABLE_STATUSES.include?(status)
  end

  def succeed!(external_id: nil)
    update!(status: :succeeded, external_id:, error: nil, delivered_at: Time.current)
  end

  def fail!(message)
    update!(status: :failed, error: message.to_s.truncate(1_000), delivered_at: nil)
  end

  def skip!(reason)
    update!(status: :skipped, error: reason.to_s.truncate(1_000), delivered_at: nil)
  end
end
