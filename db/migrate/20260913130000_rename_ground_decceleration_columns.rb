# frozen_string_literal: true

# `decceleration` is a misspelling the game files carry in their `Handling/Power`
# block, and it travelled from there into the column, the API field and the
# filter name. The parsed tree keeps the game's spelling because that is what it
# reads; everything we own says deceleration.
#
# This renames the public filter and sort key as well -- `ground_decceleration`
# is in Model.ransackable_attributes -- so a client that spelled it the old way
# gets a 400 rather than silently unfiltered results.
class RenameGroundDeccelerationColumns < ActiveRecord::Migration[8.1]
  def change
    rename_column :models, :ground_decceleration, :ground_deceleration
    rename_column :model_builds, :ground_decceleration, :ground_deceleration
  end
end
