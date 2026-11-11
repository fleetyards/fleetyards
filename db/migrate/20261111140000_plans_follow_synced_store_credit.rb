# frozen_string_literal: true

class PlansFollowSyncedStoreCredit < ActiveRecord::Migration[8.1]
  # Plans saved before the store credit was synced hold the form's old default
  # of 0, which reads as "this plan has no credit" and hides the synced one.
  def up
    execute "UPDATE hangar_plans SET starting_credit = NULL WHERE starting_credit = 0"
  end

  def down
  end
end
