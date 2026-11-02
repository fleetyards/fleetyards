# frozen_string_literal: true

class AddEmailKeyToRaffleEntries < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :raffle_entries, :email_key, :string
    add_index :raffle_entries, [:raffle_id, :email_key], unique: true, where: "email_key IS NOT NULL", algorithm: :concurrently
  end
end
