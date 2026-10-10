# frozen_string_literal: true

class AddFleetAnnouncementRecipientIndexToNotifications < ActiveRecord::Migration[8.1]
  def change
    # One notification per member for each fleet announcement, so a retried or
    # duplicated fan-out inserts nothing a second time and delivers nothing
    # twice.
    add_index :notifications, %i[user_id record_id],
      unique: true,
      where: "notification_type = 'fleet_announcement_posted' AND record_id IS NOT NULL",
      name: "index_notifications_on_fleet_announcement_recipient"
  end
end
