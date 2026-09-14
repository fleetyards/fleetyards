# frozen_string_literal: true

class AddKofiTransactionIdToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    # Ko-fi's own id for the payment, so a replayed webhook updates the row it
    # already wrote. Partial unique index matching the patreon_member_id one.
    add_column :supporter_contributions, :kofi_transaction_id, :string
    add_index :supporter_contributions, :kofi_transaction_id,
      unique: true,
      where: "kofi_transaction_id IS NOT NULL"
  end
end
