# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :body
      t.string :link
      t.string :icon
      t.datetime :read_at
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :notifications, [:user_id, :created_at], order: {created_at: :desc}
    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, :expires_at
    add_index :notifications, :notification_type
  end
end
