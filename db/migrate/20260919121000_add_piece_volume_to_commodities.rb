# frozen_string_literal: true

# What one piece of a counted commodity takes up, in SCU.
#
# Without it a position recorded in pieces has no volume, and `stock_volume`
# counts it as unmeasured -- so the moment an inventory could record pieces at
# all, the hold-fill figure would start silently understating itself.
#
# Null for the 176 bulk commodities: their "piece" is a crate, and they are sold
# in seven sizes from 1 to 32 SCU, so there is no single figure to state. Every
# one of the 56 counted commodities declares exactly one.
#
# The scale carries the smallest the game states -- a Vent Slug at one microSCU,
# which is 0.000001 SCU.
class AddPieceVolumeToCommodities < ActiveRecord::Migration[8.1]
  def change
    add_column :commodities, :piece_volume, :decimal, precision: 16, scale: 8
    add_column :commodity_builds, :piece_volume, :decimal, precision: 16, scale: 8
  end
end
