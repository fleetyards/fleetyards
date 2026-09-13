# frozen_string_literal: true

class CreatePayoutTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_transfers, id: :uuid do |t|
      t.references :payout_ledger, type: :uuid, null: false, foreign_key: true
      t.uuid :from_participant_id, null: false
      t.uuid :to_participant_id, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :confirmed_at
      t.uuid :confirmed_by_id
      t.timestamps
    end

    add_index :payout_transfers, :from_participant_id
    add_index :payout_transfers, :to_participant_id
    add_foreign_key :payout_transfers, :payout_participants, column: :from_participant_id
    add_foreign_key :payout_transfers, :payout_participants, column: :to_participant_id
    add_foreign_key :payout_transfers, :users, column: :confirmed_by_id
  end
end
