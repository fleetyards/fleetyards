# frozen_string_literal: true

class AdminNotificationsChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_admin_user.blank?

    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
