# frozen_string_literal: true

class AddReviewToPayoutEntries < ActiveRecord::Migration[8.1]
  def change
    # Defaults to approved so every existing entry keeps counting exactly as it
    # did; new rows set it explicitly.
    add_column :payout_entries, :review_status, :integer, default: 1, null: false
    add_column :payout_entries, :reviewed_at, :datetime
    add_column :payout_entries, :decline_reason, :text
    add_reference :payout_entries, :reviewed_by, type: :uuid, foreign_key: {to_table: :users}, index: false

    add_index :payout_entries, %i[payout_ledger_id review_status]
  end
end
