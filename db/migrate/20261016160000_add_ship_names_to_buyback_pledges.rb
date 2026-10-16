# frozen_string_literal: true

# RSI's buy-back list names only the first ship of a pledge, and none at all
# for a pack of several ("2 ships and 4 items"); its detail page lists each.
# Null until that page has been read since this column exists.
class AddShipNamesToBuybackPledges < ActiveRecord::Migration[8.1]
  def change
    add_column :buyback_pledges, :ship_names, :string, array: true
  end
end
