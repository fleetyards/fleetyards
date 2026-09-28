# frozen_string_literal: true

# == Schema Information
#
# Table name: announcement_deliveries
#
#  id                    :uuid             not null, primary key
#  attempts              :integer          default(0), not null
#  channel               :string           not null
#  delivered_at          :datetime
#  engagement            :jsonb
#  engagement_fetched_at :datetime
#  error                 :text
#  posted_parts          :jsonb            not null
#  status                :string           default("pending"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  announcement_id       :uuid             not null
#  external_id           :string
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

  # What a retry is offered on. A succeeded delivery has nothing to repeat.
  RETRYABLE_STATUSES = %w[failed skipped].freeze

  validates :channel, uniqueness: {scope: :announcement_id}

  # The columns the announcement payload renders for a delivery. `posted_parts`
  # is deliberately not among them: `record_part!` saves once per posted thread
  # part and the payload does not carry them, so broadcasting those would push
  # up to thirty identical rows for one threaded send.
  BROADCAST_ATTRIBUTES = %w[
    status external_id error delivered_at attempts engagement engagement_fetched_at
  ].freeze

  # The channels whose engagement can be read for free. X is not among them:
  # every read of a post is billed there, so its delivery links out instead.
  ENGAGEMENT_CHANNELS = %w[bluesky discord].freeze

  # How long after the post its counts are still followed. Engagement on an
  # announcement has settled well before this, and every refresh is a request
  # to someone else's API.
  ENGAGEMENT_WINDOW = 30.days

  # Hourly while a post is fresh and still moving, daily after that.
  ENGAGEMENT_FRESH_AGE = 2.days
  ENGAGEMENT_FRESH_INTERVAL = 1.hour
  ENGAGEMENT_SETTLED_INTERVAL = 1.day

  # The sweep runs on the hour, and a refresh lands a few seconds past it. Held
  # to the exact interval, the next sweep would find it a few seconds short and
  # skip it, halving the cadence.
  ENGAGEMENT_SLACK = 5.minutes

  scope :engagement_trackable, -> {
    status_succeeded
      .where(channel: ENGAGEMENT_CHANNELS)
      .where(delivered_at: ENGAGEMENT_WINDOW.ago..)
  }

  after_commit :broadcast_progress, on: %i[create update]

  # A pending in-app delivery is retryable too, which a pending social one is
  # not: the fan-out is idempotent -- the recipient index makes a second run
  # insert nothing and deliver nothing -- so the worst a re-run does is check
  # completion again. That is the way out of a fan-out that stopped short,
  # where a social retry would just post the thread twice.
  def retryable?
    return true if status_pending? && channel_in_app?

    RETRYABLE_STATUSES.include?(status)
  end

  # A part that landed, recorded the moment it does. The next attempt resumes
  # from here rather than from the top -- none of the three platforms can
  # unsend a post, so re-running a thread from the first part publishes it
  # twice.
  def record_part!(reference)
    self.posted_parts = posted_parts + [reference.stringify_keys]
    save!
  end

  # A Discord post sent before the webhook waited for its messages has no id
  # to read reactions back from, and never will.
  def engagement_trackable?
    return false unless status_succeeded? && ENGAGEMENT_CHANNELS.include?(channel)
    return true unless channel_discord?

    posted_parts.any? { |part| part["message_id"].present? }
  end

  def engagement_due?(now = Time.current)
    return false unless engagement_trackable?
    return false if delivered_at.blank? || delivered_at < now - ENGAGEMENT_WINDOW
    return true if engagement_fetched_at.blank?

    interval = (delivered_at > now - ENGAGEMENT_FRESH_AGE) ? ENGAGEMENT_FRESH_INTERVAL : ENGAGEMENT_SETTLED_INTERVAL

    engagement_fetched_at <= now - interval + ENGAGEMENT_SLACK
  end

  # Where the post can be opened. Built from the ids each platform handed back,
  # so a Discord message posted before those were kept has no link.
  def post_url
    return nil unless status_succeeded?

    case channel
    when "x" then x_url
    when "bluesky" then bluesky_url
    when "discord" then discord_url
    end
  end

  def posted_count
    posted_parts.size
  end

  def last_posted_part
    posted_parts.last
  end

  def first_posted_part
    posted_parts.first
  end

  # What the conditional claim matches on. A pending in-app delivery is already
  # pending, so the claim has to accept that status or the re-run is refused
  # by the very statement meant to let it through.
  def claimable_statuses
    (status_pending? && channel_in_app?) ? RETRYABLE_STATUSES + ["pending"] : RETRYABLE_STATUSES
  end

  def succeed!(external_id: nil)
    update!(status: :succeeded, external_id:, error: nil, delivered_at: Time.current)
  end

  def fail!(message)
    update!(status: :failed, error: message.to_s.truncate(1_000), delivered_at: nil)
  end

  # A delivery that got some of its thread out and then stopped. Worth saying
  # out loud in the admin, because a retry here continues rather than repeats.
  def partial?
    status_failed? && posted_parts.any?
  end

  def skip!(reason)
    update!(status: :skipped, error: reason.to_s.truncate(1_000), delivered_at: nil)
  end

  private def x_url
    return nil if external_id.blank?

    "https://x.com/i/status/#{external_id}"
  end

  # at://<did>/app.bsky.feed.post/<rkey>
  private def bluesky_url
    did, collection, rkey = external_id.to_s.delete_prefix("at://").split("/")
    return nil if [did, rkey].any?(&:blank?) || collection != "app.bsky.feed.post"

    "https://bsky.app/profile/#{did}/post/#{rkey}"
  end

  private def discord_url
    first = first_posted_part || {}
    guild_id = engagement&.dig("guild_id")
    return nil if [guild_id, first["channel_id"], first["message_id"]].any?(&:blank?)

    "https://discord.com/channels/#{guild_id}/#{first["channel_id"]}/#{first["message_id"]}"
  end

  # Loaded fresh rather than read through `announcement`: the row is built by
  # `Announcement#delivery_for`, which reaches it through
  # `deliveries.find_or_initialize_by`, and the payload has to contain the
  # transition that just committed.
  private def broadcast_progress
    return if (saved_changes.keys & BROADCAST_ATTRIBUTES).empty?

    Announcement.find_by(id: announcement_id)&.broadcast_to_admins
  end
end
