# frozen_string_literal: true

class AddPersonalContractsEnabledToFleets < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :personal_contracts_enabled, :boolean, default: true, null: false
  end
end
