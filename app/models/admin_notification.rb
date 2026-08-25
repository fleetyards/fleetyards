# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_notifications
#
#  id                :uuid             not null, primary key
#  archived_at       :datetime
#  body              :text
#  dedupe_key        :string
#  expires_at        :datetime         not null
#  icon              :string
#  last_occurred_at  :datetime         not null
#  link              :string
#  notification_type :string           not null
#  occurrences       :integer          default(1), not null
#  read_at           :datetime
#  record_type       :string
#  severity          :string           default("info"), not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  admin_user_id     :uuid             not null
#  record_id         :uuid
#
# Indexes
#
#  index_admin_notifications_on_admin_user_id_and_archived_at  (admin_user_id,archived_at)
#  index_admin_notifications_on_admin_user_id_and_created_at   (admin_user_id,created_at DESC)
#  index_admin_notifications_on_admin_user_id_and_read_at      (admin_user_id,read_at)
#  index_admin_notifications_on_dedupe                         (admin_user_id,notification_type,dedupe_key) UNIQUE WHERE ((read_at IS NULL) AND (archived_at IS NULL) AND (dedupe_key IS NOT NULL))
#  index_admin_notifications_on_expires_at                     (expires_at)
#  index_admin_notifications_on_notification_type              (notification_type)
#  index_admin_notifications_on_record                         (record_type,record_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id) ON DELETE => cascade
#
class AdminNotification < ApplicationRecord
  belongs_to :admin_user
  belongs_to :record, polymorphic: true, optional: true

  enum :notification_type, {
    paints_import: "paints_import",
    modules_import: "modules_import",
    loaner_sync: "loaner_sync",
    uex_prices_import: "uex_prices_import",
    uex_commodity_prices_import: "uex_commodity_prices_import",
    new_supporter: "new_supporter",
    rsi_api_blocked: "rsi_api_blocked",
    rsi_api_unblocked: "rsi_api_unblocked",
    weekly_stats: "weekly_stats"
  }

  enum :severity, {
    info: "info",
    warning: "warning",
    error: "error"
  }, prefix: true

  TYPES = {
    paints_import: {
      retention: 30.days,
      access: [:models],
      icon: "fa-duotone fa-palette"
    },
    modules_import: {
      retention: 30.days,
      access: [:models],
      icon: "fa-duotone fa-microchip"
    },
    loaner_sync: {
      retention: 30.days,
      access: [:models],
      icon: "fa-duotone fa-rocket-launch"
    },
    uex_prices_import: {
      retention: 30.days,
      access: [:models],
      icon: "fa-duotone fa-tags"
    },
    uex_commodity_prices_import: {
      retention: 30.days,
      access: [:models],
      icon: "fa-duotone fa-boxes-stacked"
    },
    new_supporter: {
      retention: 90.days,
      access: [:supporters],
      icon: "fa-duotone fa-hand-holding-heart"
    },
    rsi_api_blocked: {
      retention: 30.days,
      access: [:"rsi-api-status"],
      icon: "fa-duotone fa-plug-circle-xmark"
    },
    rsi_api_unblocked: {
      retention: 30.days,
      access: [:"rsi-api-status"],
      icon: "fa-duotone fa-plug-circle-check"
    },
    weekly_stats: {
      retention: 30.days,
      access: [:stats],
      icon: "fa-duotone fa-chart-line"
    }
  }.freeze

  before_validation :set_expires_at, on: :create
  before_validation :set_last_occurred_at, on: :create

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :inbox, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :expired, -> { where(expires_at: ...Time.current) }
  scope :active, -> { where(expires_at: Time.current..) }

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = ["createdAt asc", "createdAt desc"].freeze

  paginates_per 25

  ransack_alias :search, :title_or_body

  # Sortable rather than filterable: the inbox keeps what has not been dealt
  # with on top, whichever way the client sorts underneath.
  ransacker :unread, type: :boolean do
    Arel.sql("admin_notifications.read_at IS NULL")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[notification_type severity read_at archived_at created_at title body search unread]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.type_config(type)
    TYPES.fetch(type.to_sym)
  end

  def self.retention_for(type)
    type_config(type)[:retention]
  end

  def self.access_for(type)
    type_config(type)[:access]
  end

  def self.icon_for(type)
    type_config(type)[:icon]
  end

  def self.recipients_for(type)
    access = access_for(type)

    AdminUser.all.select { |admin_user| admin_user.has_access?(access) }
  end

  def self.types_for(admin_user)
    TYPES.select { |_type, config| admin_user.has_access?(config[:access]) }.keys.map(&:to_s)
  end

  # A dedupe_key folds repeat reports of the same content into the row that is
  # still unread, so a weekly job that keeps finding nothing does not stack up.
  def self.notify!(type:, title:, body: nil, severity: :info, link: nil, icon: nil, record: nil, dedupe_key: nil)
    recipients_for(type).map do |admin_user|
      notification = upsert_for(
        admin_user:, type:, title:, body:, severity:, link:,
        icon: icon || icon_for(type), record:, dedupe_key:
      )

      broadcast(notification)

      notification
    end
  end

  def self.upsert_for(admin_user:, type:, title:, body:, severity:, link:, icon:, record:, dedupe_key:)
    retried = false

    begin
      # Matching the partial unique index: an archived notification has been
      # dealt with, so a repeat report starts a new row in the inbox.
      existing = dedupe_key.presence && inbox.unread.find_by(
        admin_user:, notification_type: type, dedupe_key:
      )

      if existing
        existing.update!(
          title:, body:, severity:, link:, icon:, record:,
          occurrences: existing.occurrences + 1,
          last_occurred_at: Time.current,
          expires_at: Time.current + retention_for(type)
        )

        return existing
      end

      # A concurrent report can insert the same dedupe key between the lookup
      # and the insert; the partial unique index turns that into a conflict we
      # replay into the update branch above. The savepoint keeps a surrounding
      # transaction usable after the failed insert.
      transaction(requires_new: true) do
        create!(
          admin_user:, notification_type: type, title:, body:, severity:,
          link:, icon:, record:, dedupe_key:
        )
      end
    rescue ActiveRecord::RecordNotUnique
      raise if retried

      retried = true
      retry
    end
  end
  private_class_method :upsert_for

  def self.broadcast(notification)
    AdminNotificationsChannel.broadcast_to(notification.admin_user, notification.to_jbuilder_hash)
  rescue => e
    Rails.logger.error("Admin notification delivery failed for #{notification.id}: #{e.message}")
  end
  private_class_method :broadcast

  # The default derives "api/v1/admin_notifications/admin_notification"; the
  # admin API namespaces its views one level deeper and drops the prefix.
  def jbuilder_template_path
    "admin/api/v1/notifications/notification"
  end

  def jbuilder_template_instance_name
    :notification
  end

  def read?
    read_at.present?
  end

  def archived?
    archived_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current)
  end

  def mark_as_unread!
    without_dedupe_conflict { update!(read_at: nil) }
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    without_dedupe_conflict { update!(archived_at: nil) }
  end

  # The dedupe index only covers what is unread and still in the inbox, so
  # moving a notification back into that set can collide with the row that
  # absorbed the repeats in the meantime. This one gives up its claim on the key
  # rather than the move failing - it is the older report of the two.
  private def without_dedupe_conflict
    yield
  rescue ActiveRecord::RecordNotUnique
    raise if dedupe_key.nil?

    self.dedupe_key = nil

    yield
  end

  private def set_expires_at
    self.expires_at ||= Time.current + self.class.retention_for(notification_type)
  end

  private def set_last_occurred_at
    self.last_occurred_at ||= Time.current
  end
end
