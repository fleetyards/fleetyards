# frozen_string_literal: true

# Buy-backs used to start out without a token, and one bought as it is had no
# way to be given one, so the plans holding them count tokens as unused. Tokens
# beyond what a user holds still go to the dearest buy-backs, so marking all of
# them cannot overspend.
class MarkBuybackRoutesAsSpendingAToken < ActiveRecord::Migration[8.1]
  def up
    HangarPlanAcquisition.where(start_kind: "buyback", uses_buyback_token: false).update_all(uses_buyback_token: true)
    HangarPlanUpgradeStep.where(source_kind: "buyback", uses_buyback_token: false).update_all(uses_buyback_token: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
