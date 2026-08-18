# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :uuid             not null, primary key
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
#  index_notifications_on_expires_at              (expires_at)
#  index_notifications_on_notification_type       (notification_type)
#  index_notifications_on_record                  (record_type,record_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at     (user_id,read_at)
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

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :expired, -> { where(expires_at: ...Time.current) }
  scope :active, -> { where(expires_at: Time.current..) }

  DEFAULT_SORTING_PARAMS = "created_at desc"
  ALLOWED_SORTING_PARAMS = ["createdAt asc", "createdAt desc"].freeze

  paginates_per 25

  def self.ransackable_attributes(_auth_object = nil)
    %w[notification_type read_at created_at]
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
      UserNotificationsChannel.broadcast_to(notification.user, notification.to_jbuilder_json)
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

  def mark_as_read!
    update!(read_at: Time.current)
  end

  private def set_expires_at
    self.expires_at ||= Time.current + self.class.retention_for(notification_type)
  end
end
