class AddVatRateToHangarPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_plans, :vat_rate, :decimal, precision: 5, scale: 2
  end
end
