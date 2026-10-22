class AddRsiBuybackTokensToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :rsi_buyback_tokens, :integer
  end
end
