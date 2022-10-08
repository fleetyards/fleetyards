class AddFieldsToShops < ActiveRecord::Migration[6.1]
  def change
    add_column :shops, :accepts_stolen_goods, :boolean, default: false
    add_column :shops, :profit_margin, :decimal, precision: 15, scale: 2
    add_column :shops, :rsi_reference, :string
  end
end
