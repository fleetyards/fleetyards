# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :uuid             not null, primary key
#  archived_at       :datetime
#  body              :text
#  expires_at        :datetime         not null
#  icon              :string
#  link              :string
#  notification_type :string           not null
#  read_at           :datetime
#  record_type       :string
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  record_id         :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_notifications_on_expires_at               (expires_at)
#  index_notifications_on_notification_type        (notification_type)
#  index_notifications_on_record                   (record_type,record_id)
#  index_notifications_on_user_id_and_archived_at  (user_id,archived_at)
#  index_notifications_on_user_id_and_created_at   (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at      (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :record, polymorphic: true, optional: true

  enum :notification_type, {
    hangar_create: "hangar_create",
    hangar_destroy: "hangar_destroy",
    wishlist_create: "wishlist_create",
    wishlist_destroy: "wishlist_destroy",
    model_on_sale: "model_on_sale",
    new_model: "new_model",
    hangar_sync_finished: "hangar_sync_finished",
    hangar_sync_failed: "hangar_sync_failed",
    fleet_invite: "fleet_invite",
    fleet_member_requested: "fleet_member_requested",
    fleet_member_accepted: "fleet_member_accepted",
    fleet_request_accepted: "fleet_request_accepted",
    fleet_inventory_item_added: "fleet_inventory_item_added",
    fleet_event_published: "fleet_event_published",
    fleet_event_locked: "fleet_event_locked",
    fleet_event_starting_soon: "fleet_event_starting_soon",
    fleet_event_started: "fleet_event_started",
    fleet_event_completed: "fleet_event_completed",
    fleet_event_cancelled: "fleet_event_cancelled",
    fleet_event_signup_added: "fleet_event_signup_added",
    fleet_event_signup_withdrawn: "fleet_event_signup_withdrawn",
    fleet_event_signup_confirmed: "fleet_event_signup_confirmed",
    fleet_event_signup_assigned: "fleet_event_signup_assigned",
    fleet_event_signup_kicked: "fleet_event_signup_kicked"
  }

  TYPES = {
    hangar_create: {
      retention: 7.days,
      channels: %i[app]
    },
    hangar_destroy: {
      retention: 7.days,
      channels: %i[app]
    },
    wishlist_create: {
      retention: 7.days,
      channels: %i[app]
    },
    wishlist_destroy: {
      retention: 7.days,
      channels: %i[app]
    },
    model_on_sale: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) { VehicleMailer.on_sale(notification.record).deliver_later },
      preference_defaults: {app: false, mail: false, push: false}
    },
    new_model: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) { ModelMailer.notify_new(notification.user.email, notification.record).deliver_later }
    },
    hangar_sync_finished: {
      retention: 90.days,
      channels: %i[app]
    },
    hangar_sync_failed: {
      retention: 90.days,
      channels: %i[app]
    },
    fleet_invite: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) {
        membership = notification.record
        FleetMembershipMailer.new_invite(notification.user.email, notification.user.username, membership.fleet).deliver_later
      },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_member_requested: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) {
        membership = notification.record
        FleetMembershipMailer.member_requested(notification.user.email, membership.user.username, membership.fleet).deliver_later
      },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_member_accepted: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) {
        membership = notification.record
        FleetMembershipMailer.member_accepted(notification.user.email, membership.user.username, membership.fleet).deliver_later
      },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_request_accepted: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) {
        membership = notification.record
        FleetMembershipMailer.fleet_accepted(notification.user.email, notification.user.username, membership.fleet).deliver_later
      },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_inventory_item_added: {
      retention: 14.days,
      channels: %i[app],
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_published: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.published(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_locked: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.locked(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_starting_soon: {
      retention: 7.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.starting_soon(notification).deliver_later },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_event_started: {
      retention: 7.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.started(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_completed: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.completed(notification).deliver_later },
      preference_defaults: {app: false, mail: false, push: false}
    },
    fleet_event_cancelled: {
      retention: 30.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.cancelled(notification).deliver_later },
      preference_defaults: {app: true, mail: true, push: false}
    },
    fleet_event_signup_added: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.signup_added(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_signup_withdrawn: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.signup_withdrawn(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_signup_confirmed: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.signup_confirmed(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_signup_assigned: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.signup_assigned(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    },
    fleet_event_signup_kicked: {
      retention: 14.days,
      channels: %i[app mail],
      mailer: ->(notification) { FleetEventMailer.signup_kicked(notification).deliver_later },
      preference_defaults: {app: true, mail: false, push: false}
    }
  }.freeze

  before_validation :set_expires_at, on: :create

  # How long an archived notification is kept before it is deleted for good.
  # `expires_at` no longer ends a notification - it files it away, and this is
  # the term that ends it.
  ARCHIVE_RETENTION = 90.days

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :inbox, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :expired, -> { where(expires_at: ...Time.current) }
  scope :active, -> { where(expires_at: Time.current..) }
  scope :purgeable, -> { where(archived_at: ...ARCHIVE_RETENTION.ago) }
  # What each tab shows. Expiry files a notification into the archive, and the
  # cleanup job only writes that down once a day - so the tabs apply the same
  # rule themselves and a notification moves the moment its date passes.
  scope :pending, -> { inbox.active }
  scope :filed, -> { where(archived_at: ..Time.current).or(expired) }

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = ["createdAt asc", "createdAt desc"].freeze

  paginates_per 25

  ransack_alias :search, :title_or_body

  # Sortable rather than filterable: the inbox keeps what has not been read on
  # top, whichever way the client sorts underneath.
  ransacker :unread, type: :boolean do
    Arel.sql("notifications.read_at IS NULL")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[notification_type read_at archived_at created_at title body search unread]
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

  def self.channels_for(type)
    type_config(type)[:channels]
  end

  def self.mailer_for(type)
    type_config(type)[:mailer]
  end

  def self.preference_defaults_for(type)
    type_config(type).fetch(:preference_defaults, {app: true, mail: false, push: false})
  end

  # Retention files a notification into the archive rather than making it
  # vanish: the reader keeps a way to find it, and `purgeable` is what
  # eventually removes it. Runs daily, so a notification can sit in the inbox
  # for up to a day past its date - immaterial against retentions of a week and
  # up, and the alternative is a scope that hides rows the archive tab then has
  # to un-hide.
  def self.archive_expired!
    expired.inbox.in_batches(of: 1000).update_all(archived_at: Time.current, updated_at: Time.current)
  end

  def self.notify!(user:, type:, title:, body: nil, link: nil, icon: nil, record: nil)
    preference = NotificationPreference.for(user:, type:)

    notification = create!(
      user:,
      notification_type: type,
      title:,
      body:,
      link:,
      icon:,
      record:,
      read_at: preference.app? ? nil : Time.current
    )

    deliver_channels(notification, preference)

    notification
  end

  def self.deliver_channels(notification, preference)
    if preference.app?
      UserNotificationsChannel.broadcast_to(notification.user, notification.to_jbuilder_hash)
    end

    if preference.mail?
      mailer = mailer_for(notification.notification_type)
      mailer&.call(notification)
    end
  rescue => e
    Rails.logger.error("Notification delivery failed for #{notification.id}: #{e.message}")
  end
  private_class_method :deliver_channels

  def read?
    read_at.present?
  end

  def archived?
    archived_at.present?
  end

  # What the reading pane counts down to once a notification is archived. Nil
  # while it is still in the inbox, where `expires_at` is the next date.
  def deletes_at
    archived_at && archived_at + ARCHIVE_RETENTION
  end

  def mark_as_read!
    update!(read_at: Time.current)
  end

  def mark_as_unread!
    update!(read_at: nil)
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  private def set_expires_at
    self.expires_at ||= Time.current + self.class.retention_for(notification_type)
  end
end
