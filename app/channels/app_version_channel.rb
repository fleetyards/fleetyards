# frozen_string_literal: true

class AppVersionChannel < ApplicationCable::Channel
  def subscribed
    stream_from "app_version"

    # A deploy replaces the containers serving the cable, so every client
    # reconnects to the new release; answering on subscribe tells it the
    # version without waiting for the broadcast.
    transmit AppVersion.payload
  end

  def unsubscribed
    stop_all_streams
  end
end
