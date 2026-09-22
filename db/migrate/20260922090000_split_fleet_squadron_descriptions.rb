# frozen_string_literal: true

# Two descriptions, named for what they are rather than for their length: the
# short one is the line a squadron card carries, `description` is the squadron's
# own page.
#
# The rename comes first and is what frees the name the new column takes. A
# migration of its own rather than a correction to the create: the table is new
# and unmerged, but it already holds squadrons in development, and rebuilding it
# to tidy the history would take them with it.
class SplitFleetSquadronDescriptions < ActiveRecord::Migration[7.2]
  def change
    rename_column :fleet_squadrons, :description, :short_description

    add_column :fleet_squadrons, :description, :text
  end
end
