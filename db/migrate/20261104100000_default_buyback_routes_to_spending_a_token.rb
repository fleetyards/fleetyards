# frozen_string_literal: true

class DefaultBuybackRoutesToSpendingAToken < ActiveRecord::Migration[8.1]
  def change
    change_column_default :hangar_plan_acquisitions, :uses_buyback_token, from: false, to: true
    change_column_default :hangar_plan_upgrade_steps, :uses_buyback_token, from: false, to: true
  end
end
