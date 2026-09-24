# frozen_string_literal: true

class AddSquadronVisibility < ActiveRecord::Migration[8.0]
  # A contract has never had a visibility of its own -- the privilege gate was
  # the whole of it -- so it gains the column at the value that keeps today's
  # behaviour, and the squadron restriction is the second value.
  def change
    add_column :fleet_contracts, :visibility, :integer, default: 0, null: false
  end
end
