class CreateNotificationChannels < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_channels, id: :uuid do |t|
      t.uuid :user_id
      t.string :channel
      t.string :unsubscribe_token
      t.boolean :confirmed, default: false

      t.timestamps
    end
  end
end
