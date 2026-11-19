# frozen_string_literal: true

# The admin side of a feedback conversation, so a reply from the user shows up
# on the page an admin has open.
class AdminFeedbackChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_admin_user&.has_access?(["feedback"])

    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
