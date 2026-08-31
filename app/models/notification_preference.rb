# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_preferences
#
#  id                :uuid             not null, primary key
#  app               :boolean          default(TRUE), not null
#  discord           :boolean          default(FALSE), not null
#  mail              :boolean          default(FALSE), not null
#  notification_type :string           not null
#  push              :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_user_id_notification_type_2ab4363e9b  (user_id,notification_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class NotificationPreference < ApplicationRecord
  # Every delivery channel, with its off-by-default value. One source of truth
  # on purpose: a channel that exists here but not in one of the places that
  # build a full row breaks User#create_default_notification_preferences, whose
  # insert_all needs every row to carry identical keys.
  CHANNEL_DEFAULTS = {app: true, mail: false, push: false, discord: false}.freeze

  belongs_to :user

  enum :notification_type, Notification.notification_types

  validates :notification_type, presence: true, uniqueness: {scope: :user_id}

  def self.for(user:, type:)
    find_by(user:, notification_type: type) || new(user:, notification_type: type, **defaults_for(type))
  end

  def self.defaults_for(type)
    Notification.preference_defaults_for(type)
  end

  def self.mail_available?(type)
    Notification.channels_for(type).include?(:mail)
  end

  def self.push_available?(type)
    Notification.channels_for(type).include?(:push)
  end

  # Availability is per user here, not only per type: a DM needs somewhere to
  # go, so the column is offered to readers who linked a Discord account and
  # nobody else.
  def self.discord_available?(type, user:)
    return false unless Notification.channels_for(type).include?(:discord)

    user.present? && user.omniauth_connections.exists?(provider: "discord")
  end
end
