# frozen_string_literal: true

class RoadmapChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'roadmap'
  end

  def unsubscribed
    stop_all_streams
  end
end
