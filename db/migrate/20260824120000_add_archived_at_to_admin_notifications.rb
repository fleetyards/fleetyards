# frozen_string_literal: true

class AddArchivedAtToAdminNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_notifications, :archived_at, :datetime
    add_index :admin_notifications, [:admin_user_id, :archived_at]

    # A repeat report belongs back in the inbox rather than folded into a row
    # somebody already archived, so an archived notification stops absorbing
    # its dedupe key.
    remove_index :admin_notifications, column: [:admin_user_id, :notification_type, :dedupe_key],
      unique: true, where: "read_at IS NULL AND dedupe_key IS NOT NULL",
      name: "index_admin_notifications_on_dedupe"
    add_index :admin_notifications, [:admin_user_id, :notification_type, :dedupe_key],
      unique: true, where: "read_at IS NULL AND archived_at IS NULL AND dedupe_key IS NOT NULL",
      name: "index_admin_notifications_on_dedupe"
  end
end
