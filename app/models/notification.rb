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
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  index_notifications_on_expires_at              (expires_at)
#  index_notifications_on_notification_type       (notification_type)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at     (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user

  enum :notification_type, {
    hangar_create: "hangar_create",
    hangar_destroy: "hangar_destroy",
    wishlist_create: "wishlist_create",
    wishlist_destroy: "wishlist_destroy",
    model_on_sale: "model_on_sale",
    on_sale: "on_sale",
    new_model: "new_model",
    hangar_sync_finished: "hangar_sync_finished",
    hangar_sync_failed: "hangar_sync_failed"
  }

  RETENTION = {
    7.days => %w[hangar_create hangar_destroy wishlist_create wishlist_destroy],
    30.days => %w[model_on_sale on_sale new_model],
    90.days => %w[hangar_sync_finished hangar_sync_failed]
  }.freeze

  before_validation :set_expires_at, on: :create

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :expired, -> { where(expires_at: ...Time.current) }
  scope :active, -> { where(expires_at: Time.current..) }

  paginates_per 25

  def self.ransackable_attributes(_auth_object = nil)
    %w[notification_type read_at created_at]
  end

  def self.retention_for(type)
    RETENTION.each do |duration, types|
      return duration if types.include?(type.to_s)
    end
    7.days
  end

  def self.notify!(user:, type:, title:, body: nil, link: nil, icon: nil)
    notification = create!(
      user:,
      notification_type: type,
      title:,
      body:,
      link:,
      icon:
    )

    UserNotificationsChannel.broadcast_to(user, notification.to_jbuilder_json)

    notification
  end

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
