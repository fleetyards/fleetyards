class AddIndexForNotificationChannels < ActiveRecord::Migration[6.1]
  def change
    add_index :notification_channels, [:user_id, :channel], unique: true
  end
end
