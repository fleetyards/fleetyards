# frozen_string_literal: true

class AddAnnouncementRecipientIndexToNotifications < ActiveRecord::Migration[8.1]
  def change
    # One announcement notification per reader, enforced rather than assumed.
    #
    # The fan-out is ~58 jobs deep and every one of them retries, so a batch
    # that dies after its insert would otherwise write its thousand readers a
    # second row -- and send the opted-in ones a second mail -- on the way
    # back. With this index the insert is a no-op on the second run and returns
    # nothing, so nothing is delivered twice either.
    #
    # Partial, because it is a rule about announcements: every other type is
    # free to write the same reader as many rows as it has events.
    add_index :notifications, %i[user_id record_id],
      unique: true,
      where: "notification_type = 'announcement' AND record_id IS NOT NULL",
      name: "index_notifications_on_announcement_recipient"
  end
end
