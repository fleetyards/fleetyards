# frozen_string_literal: true

class CreateRaffles < ActiveRecord::Migration[8.1]
  def change
    create_table :raffles, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.references :model, type: :uuid, foreign_key: true
      t.text :code
      t.datetime :starts_at, null: false
      t.integer :run_days, null: false, default: 14
      t.datetime :ends_at, null: false
      t.integer :claim_period_days, null: false, default: 3
      t.boolean :published, null: false, default: false
      t.datetime :start_announced_at
      t.datetime :last_day_announced_at
      t.datetime :drawn_at
      t.references :drawn_by, type: :uuid, foreign_key: {to_table: :admin_users, on_delete: :nullify}
      t.datetime :concluded_at

      t.timestamps
    end

    add_index :raffles, :published
    add_index :raffles, :ends_at

    create_table :raffle_entries, id: :uuid do |t|
      t.references :raffle, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :user, type: :uuid, foreign_key: {on_delete: :nullify}, index: false
      t.string :username
      t.text :email
      t.datetime :conditions_accepted_at, null: false
      t.string :conditions_version, null: false
      t.integer :draw_position
      t.datetime :won_at
      t.datetime :claim_deadline_at
      t.datetime :claimed_at
      t.datetime :forfeited_at
      t.string :claim_mail_message_id
      t.string :claim_mail_status
      t.string :prize_mail_message_id
      t.string :prize_mail_status
      t.datetime :prize_mail_sent_at

      t.timestamps
    end

    add_index :raffle_entries, [:user_id, :raffle_id], unique: true
    add_index :raffle_entries, [:raffle_id, :draw_position], unique: true
    add_index :raffle_entries, :claim_deadline_at, where: "claimed_at IS NULL AND forfeited_at IS NULL"

    # One announcement per user, raffle and kind, so a retried fan-out batch
    # inserts nothing twice.
    add_index :notifications, [:user_id, :record_id, :notification_type],
      unique: true,
      where: "notification_type IN ('raffle_started', 'raffle_last_day') AND record_id IS NOT NULL",
      name: "index_notifications_on_raffle_announcement_recipient"
  end
end
