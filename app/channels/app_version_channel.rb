# frozen_string_literal: true

class AppVersionChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'app_version'
  end

  def unsubscribed
    stop_all_streams
  end
end
