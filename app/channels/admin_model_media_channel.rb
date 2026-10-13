# frozen_string_literal: true

# A folder of views is cropped by a job per view after the save has answered,
# and each crop replaces the blob the response named. This says when one lands,
# so the edit page can reload the model instead of showing purged files.
class AdminModelMediaChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_admin_user.blank?

    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
