# frozen_string_literal: true

# Every fleet carries a verification token from the start, so a manager is
# never asked to make one before they can prove their org.
class BackfillFleetRsiVerificationTokens < ActiveRecord::Migration[8.1]
  def up
    Fleet.unscoped.where(rsi_verification_token: nil).in_batches(of: 1000) do |batch|
      batch.pluck(:id).each do |id|
        Fleet.unscoped.where(id:).update_all(rsi_verification_token: Fleet.new_rsi_verification_token)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
