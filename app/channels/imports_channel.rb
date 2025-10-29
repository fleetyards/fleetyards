# frozen_string_literal: true

class ImportsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
