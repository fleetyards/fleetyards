# frozen_string_literal: true

# A conversation about feedback as it moves: replies from either side and the
# status. Per user, like the other channels: the stream carries only the
# user's own feedback, so it needs no authorization of its own.
class FeedbackChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_user.blank?

    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
