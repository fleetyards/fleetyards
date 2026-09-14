# frozen_string_literal: true

class AddClaimKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    # Generated on first view rather than for every account, the way
    # fleets.calendar_feed_token already is — most users never donate, and an
    # unused key is one more secret to rotate for nothing.
    add_column :users, :claim_key, :string
    add_index :users, :claim_key, unique: true, where: "claim_key IS NOT NULL"
  end
end
