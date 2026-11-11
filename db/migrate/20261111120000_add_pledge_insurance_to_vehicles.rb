# frozen_string_literal: true

class AddPledgeInsuranceToVehicles < ActiveRecord::Migration[8.1]
  def change
    # Null until a hangar sync reads it, so unread is not taken for none.
    add_column :vehicles, :rsi_pledge_lifetime_insurance, :boolean
    add_column :vehicles, :rsi_pledge_insurance_months, :integer
  end
end
