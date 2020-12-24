# frozen_string_literal: true

class ProgressTrackerChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'progress_tracker'
  end

  def unsubscribed
    stop_all_streams
  end
end
