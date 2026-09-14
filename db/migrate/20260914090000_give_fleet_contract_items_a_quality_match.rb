# frozen_string_literal: true

# A contract line can now ask for a grade *exactly* as well as at-or-above it —
# a crafting job that wants quality 500 and no better is a real request, and
# "at least" could not express it.
#
# `min_quality` becomes `quality`, because a column named for a minimum that can
# also mean an exact figure is a lie the rest of the code has to work around.
# Both the column and the feature are unreleased, so this renames rather than
# leaving the misnomer in place forever.
class GiveFleetContractItemsAQualityMatch < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :fleet_contract_items,
      name: "fleet_contract_items_min_quality_range"

    rename_column :fleet_contract_items, :min_quality, :quality

    add_column :fleet_contract_items, :quality_match, :integer, null: false, default: 0

    add_check_constraint :fleet_contract_items,
      "quality IS NULL OR (quality >= 0 AND quality <= 1000)",
      name: "fleet_contract_items_quality_range"
  end
end
