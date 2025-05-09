class DropLastPledgePrice < ActiveRecord::Migration[7.1]
  def change
    remove_column :models, :last_pledge_price, :decimal, precision: 15, scale: 2
    remove_column :model_paints, :last_pledge_price, :decimal, precision: 15, scale: 2
  end
end
