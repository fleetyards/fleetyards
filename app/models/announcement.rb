# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id               :uuid             not null, primary key
#  body             :text             not null
#  discord_parts    :text             default([]), not null, is an Array
#  icon             :string
#  last_tested_at   :datetime
#  link             :string
#  notify_users     :boolean          default(TRUE), not null
#  post_bluesky     :boolean          default(FALSE), not null
#  post_discord     :boolean          default(FALSE), not null
#  post_x           :boolean          default(FALSE), not null
#  publish_at       :datetime
#  published_at     :datetime
#  recipients_count :integer
#  social_parts     :text             default([]), not null, is an Array
#  status           :string           default("draft"), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :uuid
#
# Indexes
#
#  index_announcements_on_publish_at    (publish_at) WHERE ((status)::text = 'scheduled'::text)
#  index_announcements_on_published_at  (published_at)
#  index_announcements_on_status        (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
class Announcement < ApplicationRecord
  belongs_to :admin_user, optional: true
  has_many :deliveries, class_name: "AnnouncementDelivery", dependent: :destroy

  enum :status, {
    draft: "draft",
    scheduled: "scheduled",
    publishing: "publishing",
    published: "published",
    failed: "failed"
  }, prefix: true

  # The type an announcement becomes in a reader's inbox. Named here rather
  # than inline at the call site so the preference lookup, the mailer and the
  # settings page all agree on one symbol.
  NOTIFICATION_TYPE = :announcement

  # How many readers one batch job takes. One preference query and one
  # insert_all per batch, so the figure trades statement size against job
  # count; at 57k readers this is ~58 jobs.
  FAN_OUT_BATCH_SIZE = 1_000

  DEFAULT_ICON = "fa-duotone fa-bullhorn"

  DISCORD_PART_LIMIT = Announcements::Platform::DISCORD.limit

  # Sendable once, and again after a failure. A published announcement is not
  # re-sendable -- readers already have it -- and one that is mid-flight has a
  # job already doing the work.
  PUBLISHABLE_STATUSES = %w[draft scheduled failed].freeze

  validates :title, presence: true, length: {maximum: 255}
  validates :body, presence: true
  # Measured against the platforms this announcement actually selected, and
  # measured the way each of them counts. A post can be legal on Bluesky and
  # too long for X, so the author is told at save rather than having their copy
  # quietly trimmed on the way out.
  validates :social_parts, announcement_part_length: {platforms: %i[x bluesky]}
  validates :discord_parts, announcement_part_length: {
    platform: Announcements::Platform::DISCORD,
    overhead: ->(total) { Announcements::DiscordMessages.marker_overhead(total) }
  }
  validate :publish_at_required_when_scheduled
  validate :at_least_one_channel

  before_validation :default_icon, on: :create
  before_validation :compact_parts

  # The notifications stay -- readers have them in their inbox and they carry
  # their own title, body and link -- but they stop pointing at a row that is
  # gone. Without this a deleted announcement leaves tens of thousands of
  # dangling polymorphic references behind, the way the hangar bulk delete
  # already does.
  before_destroy :detach_notifications

  # Only what the payload carries, and only what a send moves. An edit made
  # through the form is already reflected by the mutation's own invalidation,
  # and re-broadcasting it would push a title change into another admin's open
  # edit form.
  BROADCAST_ATTRIBUTES = %w[status published_at recipients_count last_tested_at].freeze

  after_commit :broadcast_progress, on: %i[create update]

  scope :due, -> { status_scheduled.where(publish_at: ..Time.current) }

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = [
    "createdAt asc", "createdAt desc",
    "publishedAt asc", "publishedAt desc",
    "title asc", "title desc"
  ].freeze

  paginates_per 25

  ransack_alias :search, :title_or_body

  def self.ransackable_attributes(_auth_object = nil)
    %w[title body status published_at publish_at created_at search]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  # Which social channels this announcement asked for. The in-app fan-out is
  # deliberately not in here: it is not a post, it has no external id, and it
  # is the one channel whose reach depends on each reader's own preferences.
  def social_channels
    AnnouncementDelivery::SOCIAL_CHANNELS.select { |channel| public_send(:"post_#{channel}") }
  end

  def channels
    (notify_users? ? [AnnouncementDelivery::IN_APP_CHANNEL] : []) + social_channels
  end

  def publishable?
    PUBLISHABLE_STATUSES.include?(status)
  end

  # Whether the author wrote the channel's copy themselves. When they did it is
  # posted verbatim -- title, link and all are theirs to place; when they did
  # not, the composers build it from title, body and link the way a one-line
  # announcement wants.
  def authored_discord?
    discord_parts.present?
  end

  def authored_social?
    social_parts.present?
  end

  def threaded?
    social_parts.size > 1
  end

  # The default derives "api/v1/announcements/announcement"; announcements have
  # no public API, and the admin one namespaces its views a level deeper.
  def jbuilder_template_path
    "admin/api/v1/announcements/announcement"
  end

  # Rendered once and handed to everybody, rather than once per admin the way
  # Import#notify_admin does it: the payload is identical, and the render is an
  # ActionController::Renderer round trip through a partial that walks the
  # deliveries.
  def broadcast_to_admins
    payload = to_jbuilder_hash

    # Per admin, so one dead socket does not cost everybody behind it the
    # broadcast -- `find_each` would otherwise unwind on the first raise. The
    # subscription only resyncs on a reconnect, and a broadcast that failed
    # server-side is not one, so those admins would sit on a stale row until
    # something else refetched it. Same shape as NotifyBatchJob#broadcast.
    AdminUser.find_each do |admin_user|
      AdminAnnouncementsChannel.broadcast_to(admin_user, payload)
    rescue => e
      Rails.logger.error("Announcement broadcast failed for #{id} to admin #{admin_user.id}: #{e.message}")
    end
  rescue => e
    # A send in flight must not be rolled back because a socket was not there:
    # this runs from after_commit, and the write it describes has already
    # landed.
    Rails.logger.error("Announcement broadcast failed for #{id}: #{e.message}")
  end

  def delivery_for(channel)
    deliveries.find_or_initialize_by(channel: channel.to_s)
  end

  # `link` is stored as a path, because that is what a notification carries and
  # what the app routes on. Every channel that leaves the app -- mail, a Discord
  # post, a tweet -- has no site around it to resolve one against.
  def absolute_link
    return nil if link.blank?
    return link if link.start_with?("http")

    "https://#{Rails.configuration.app.domain}#{link}"
  end

  private def broadcast_progress
    return if (saved_changes.keys & BROADCAST_ATTRIBUTES).empty?

    broadcast_to_admins
  end

  private def detach_notifications
    # rubocop:disable Rails/SkipsModelValidations
    Notification.where(record_type: "Announcement", record_id: id)
      .update_all(record_type: nil, record_id: nil, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # A repeatable field leaves empty rows behind when an author removes one from
  # the middle, and an empty post is not a post.
  private def compact_parts
    self.discord_parts = Array(discord_parts).map { |part| part.to_s.strip }.compact_blank
    self.social_parts = Array(social_parts).map { |part| part.to_s.strip }.compact_blank
  end

  private def default_icon
    self.icon = DEFAULT_ICON if icon.blank?
  end

  private def publish_at_required_when_scheduled
    return unless status_scheduled?
    return if publish_at.present?

    errors.add(:publish_at, :blank)
  end

  private def at_least_one_channel
    return if channels.any?

    errors.add(:base, :no_channels)
  end
end
