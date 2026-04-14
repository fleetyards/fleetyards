# frozen_string_literal: true

class CreateNotificationPreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_preferences, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :notification_type, null: false
      t.boolean :app, null: false, default: true
      t.boolean :mail, null: false, default: false
      t.boolean :push, null: false, default: false
      t.timestamps
    end

    add_index :notification_preferences, [:user_id, :notification_type], unique: true
  end
end
