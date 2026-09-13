# frozen_string_literal: true

class CreatePayoutEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_entries, id: :uuid do |t|
      t.references :payout_ledger, type: :uuid, null: false, foreign_key: true
      t.references :payout_participant, type: :uuid, null: false, foreign_key: true
      t.integer :entry_type, null: false, default: 0
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :description, null: false
      t.text :notes
      t.datetime :occurred_at
      t.uuid :recorded_by_id
      t.timestamps
    end

    add_index :payout_entries, [:payout_ledger_id, :entry_type]
    add_foreign_key :payout_entries, :users, column: :recorded_by_id
  end
end
