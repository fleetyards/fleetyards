# frozen_string_literal: true

class CreatePayoutLedgers < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_ledgers, id: :uuid do |t|
      t.string :subject_type, null: false
      t.uuid :subject_id, null: false
      t.string :status, null: false, default: "open"
      t.datetime :settled_at
      t.uuid :settled_by_id
      t.text :notes
      t.timestamps
    end

    # A subject has at most one ledger, so the polymorphic pair is the identity
    # rather than a plain lookup index.
    add_index :payout_ledgers, [:subject_type, :subject_id], unique: true
    add_foreign_key :payout_ledgers, :users, column: :settled_by_id
  end
end
