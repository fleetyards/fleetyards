# frozen_string_literal: true

class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false
      t.string :user_agent
      t.datetime :last_delivered_at
      t.datetime :last_failed_at
      t.integer :failure_count, null: false, default: 0
      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
