# frozen_string_literal: true

class CreatePayoutParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_participants, id: :uuid do |t|
      t.references :payout_ledger, type: :uuid, null: false, foreign_key: true
      t.uuid :user_id
      t.string :name
      t.uuid :added_by_id
      t.timestamps
    end

    # A guest carries a name and no account, so the uniqueness that stops one
    # person joining a ledger twice can only cover the rows that have a user.
    add_index :payout_participants,
      [:payout_ledger_id, :user_id],
      unique: true,
      where: "user_id IS NOT NULL",
      name: "index_payout_participants_unique_user_per_ledger"

    add_foreign_key :payout_participants, :users, column: :user_id
    add_foreign_key :payout_participants, :users, column: :added_by_id
  end
end
