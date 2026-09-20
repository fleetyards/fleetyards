# frozen_string_literal: true

# Carries who has just come online or gone offline among the people the reader
# has an accepted relationship with, and refreshes the reader's own connection
# while it is subscribed.
#
# The heartbeat is the half that makes a lost connection self-correct: the score
# stops being refreshed, the connection ages out, and the user falls offline
# without anybody having run a callback. ActionCable's own three-second ping is
# internal and has no public hook, hence a timer of our own.
class UserPresenceChannel < ApplicationCable::Channel
  periodically :heartbeat, every: UserPresence::HEARTBEAT_INTERVAL

  def subscribed
    return reject if current_user.blank?

    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end

  private def heartbeat
    return if current_user.blank?

    UserPresence.heartbeat(current_user.id, connection.presence_token)
  end
end
