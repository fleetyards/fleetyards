# frozen_string_literal: true

# The same transitions, unredacted. An admin sees the truth — as they already do
# for email, sign-in IPs and sign-in counts — so `show_online_status` does not
# apply here.
class AdminPresenceChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_admin_user.blank?

    stream_for current_admin_user
  end

  def unsubscribed
    stop_all_streams
  end
end
