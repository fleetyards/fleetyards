class AddBuybackTokensToHangarPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_plans, :buyback_tokens, :integer
  end
end
