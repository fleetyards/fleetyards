class AddUsesBuybackTokenToHangarPlanRoutes < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_plan_acquisitions, :uses_buyback_token, :boolean, null: false, default: false
    add_column :hangar_plan_upgrade_steps, :uses_buyback_token, :boolean, null: false, default: false
  end
end
