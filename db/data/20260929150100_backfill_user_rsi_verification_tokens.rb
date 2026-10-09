# frozen_string_literal: true

# Every user carries a verification token from the start, so nobody is asked to
# make one before they can prove their handle.
class BackfillUserRsiVerificationTokens < ActiveRecord::Migration[8.1]
  def up
    User.where(rsi_verification_token: nil).in_batches(of: 1000) do |batch|
      batch.pluck(:id).each do |id|
        User.where(id:).update_all(rsi_verification_token: User.new_rsi_verification_token)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
