# frozen_string_literal: true

# Send progress, pushed. Publishing dispatches four channels that each report
# into their own AnnouncementDelivery row from a background job, so without this
# the list an admin is looking at keeps saying `pending` until something
# refetches it.
class AdminAnnouncementsChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_admin_user.blank?

    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
