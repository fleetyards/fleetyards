# frozen_string_literal: true

class CreateAdminNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_notifications, id: :uuid do |t|
      t.references :admin_user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :notification_type, null: false
      t.string :severity, null: false, default: "info"
      t.string :title, null: false
      t.text :body
      t.string :link
      t.string :icon
      t.string :dedupe_key
      t.integer :occurrences, null: false, default: 1
      t.datetime :last_occurred_at, null: false
      t.references :record, polymorphic: true, type: :uuid, index: true
      t.datetime :read_at
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :admin_notifications, [:admin_user_id, :created_at], order: {created_at: :desc}
    add_index :admin_notifications, [:admin_user_id, :read_at]
    add_index :admin_notifications, [:admin_user_id, :notification_type, :dedupe_key],
      name: "index_admin_notifications_on_dedupe"
    add_index :admin_notifications, :expires_at
    add_index :admin_notifications, :notification_type
  end
end
