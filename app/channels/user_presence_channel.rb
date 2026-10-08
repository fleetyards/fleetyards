# frozen_string_literal: true

# Carries who has just come online or gone offline among the people the reader
# has an accepted relationship with, and refreshes the reader's own connection
# while it is subscribed.
#
# The client also reports when one of its tabs is visible, which holds push
# notifications back on every device while the user is looking at the app.
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

  # A closed tab or a shut lid sends nothing else, and until the window ran out
  # the notifications it would have toasted would reach nobody.
  def unsubscribed
    stop_all_streams

    UserPresence.mark_inactive(current_user.id) if current_user.present?
  end

  # Sent by the client while one of its tabs is visible and in use. The server
  # heartbeat cannot tell that apart from a tab left open in the background.
  def active
    return if current_user.blank?

    UserPresence.mark_active(current_user.id)
  end

  def inactive
    return if current_user.blank?

    UserPresence.mark_inactive(current_user.id)
  end

  private def heartbeat
    return if current_user.blank?

    UserPresence.heartbeat(current_user.id, connection.presence_token)
  end
end
