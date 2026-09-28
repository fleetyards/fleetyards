# frozen_string_literal: true

class AddRsiVerificationToFleets < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :rsi_verification_token, :string
    add_column :fleets, :rsi_verification_status, :string
    add_column :fleets, :rsi_verification_checked_at, :datetime
    add_column :fleets, :rsi_verified_at, :datetime
    add_column :fleets, :rsi_verified_sid, :string

    add_index :fleets, :rsi_verified_sid, unique: true, where: "discarded_at IS NULL"
  end
end
