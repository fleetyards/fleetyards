class AddRsiPledgeDataToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :rsi_pledge_slug, :string
    add_column :models, :rsi_pledge_value, :integer
  end
end
