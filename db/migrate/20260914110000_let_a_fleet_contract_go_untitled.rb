# frozen_string_literal: true

# A contract says what it wants in its goods, so making the author restate that
# in a title is busywork. An untitled one describes itself -- "Buy 800 SCU
# Titanium at 500+ quality" -- from the lines it carries.
#
# The title stays as an override rather than being dropped: a fleet that wants
# to call a job "Weekly Daymar run" should be able to.
#
# The slug cannot follow a derived title, because that title changes every time
# the goods do and a moving slug breaks every link to it. An untitled contract
# gets a slug from its kind and a random suffix, once.
class LetAFleetContractGoUntitled < ActiveRecord::Migration[8.1]
  def change
    change_column_null :fleet_contracts, :title, true
  end
end
