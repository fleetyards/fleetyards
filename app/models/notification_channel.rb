# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_channels
#
#  id                :uuid             not null, primary key
#  channel           :string
#  confirmed         :boolean          default(FALSE)
#  unsubscribe_token :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid
#
# Indexes
#
#  index_notification_channels_on_user_id_and_channel  (user_id,channel) UNIQUE
#
class NotificationChannel < ApplicationRecord
  belongs_to :user

  enum channel: { email: 0 }

  before_create :generate_unsubscribe_token

  validates :user_id, uniqueness: { scope: :channel }

  def self.confirmed
    where(confirmed: true)
  end

  def self.via_email
    where(channel: :email)
  end

  def confirm
    update(confirmed: true)
  end

  private def generate_unsubscribe_token
    return if unsubscribe_token.present?

    self.unsubscribe_token = loop do
      random_token = SecureRandom.urlsafe_base64(20, false)

      break random_token unless self.class.exists?(unsubscribe_token: random_token)
    end
  end
end
