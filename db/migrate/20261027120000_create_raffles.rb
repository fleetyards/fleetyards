# frozen_string_literal: true

class CreateRaffles < ActiveRecord::Migration[8.1]
  def change
    create_table :raffles, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.references :model, type: :uuid, foreign_key: true
      t.text :code
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :claim_period_days, null: false, default: 14
      t.boolean :published, null: false, default: false
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
      t.references :claimed_by, type: :uuid, foreign_key: {to_table: :admin_users, on_delete: :nullify}
      t.datetime :forfeited_at
      t.string :verification_code_digest
      t.datetime :verification_sent_at
      t.integer :verification_attempts, null: false, default: 0

      t.timestamps
    end

    add_index :raffle_entries, [:user_id, :raffle_id], unique: true
    add_index :raffle_entries, [:raffle_id, :draw_position], unique: true
    add_index :raffle_entries, :claim_deadline_at, where: "claimed_at IS NULL AND forfeited_at IS NULL"
  end
end
