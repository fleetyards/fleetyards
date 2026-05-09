# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_preferences
#
#  id                :uuid             not null, primary key
#  app               :boolean          default(TRUE), not null
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
end
