# frozen_string_literal: true

class AddArchivedAtToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :archived_at, :datetime
    add_index :notifications, [:user_id, :archived_at]
  end
end
