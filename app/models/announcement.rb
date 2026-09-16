# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id               :uuid             not null, primary key
#  body             :text             not null
#  icon             :string
#  link             :string
#  notify_users     :boolean          default(TRUE), not null
#  post_bluesky     :boolean          default(FALSE), not null
#  post_discord     :boolean          default(FALSE), not null
#  post_x           :boolean          default(FALSE), not null
#  publish_at       :datetime
#  published_at     :datetime
#  recipients_count :integer
#  social_body      :text
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

  validates :title, presence: true, length: {maximum: 255}
  validates :body, presence: true
  validates :social_body, length: {maximum: 280}, allow_blank: true
  validate :publish_at_required_when_scheduled
  validate :at_least_one_channel

  before_validation :default_icon, on: :create

  # The notifications stay -- readers have them in their inbox and they carry
  # their own title, body and link -- but they stop pointing at a row that is
  # gone. Without this a deleted announcement leaves tens of thousands of
  # dangling polymorphic references behind, the way the hangar bulk delete
  # already does.
  before_destroy :detach_notifications

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

  # Publishable once, and again after a failure. A published announcement is
  # not re-sendable -- readers already have it, and a second fan-out would
  # write every one of them a duplicate row.
  def publishable?
    status_draft? || status_scheduled? || status_failed?
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

  private def detach_notifications
    # rubocop:disable Rails/SkipsModelValidations
    Notification.where(record_type: "Announcement", record_id: id)
      .update_all(record_type: nil, record_id: nil, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
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
