# frozen_string_literal: true

# A place a record names can be one of ours: the free text stays, for a place
# the starmap does not carry, and the link sits beside it for one it does.
# Fleets gain a headquarters the same way, and a user's in-game whereabouts
# link to the place they are at.
class LinkLocations < ActiveRecord::Migration[8.1]
  LINKS = {
    inventories: %i[location],
    fleet_inventories: %i[location],
    fleet_events: %i[location meetup_location],
    fleet_event_occurrence_states: %i[location meetup_location],
    users: %i[current_location],
    fleets: %i[headquarters_location]
  }.freeze

  def change
    add_column :fleets, :headquarters, :string

    LINKS.each do |table, columns|
      columns.each do |column|
        add_reference table, column, type: :uuid, index: true,
          foreign_key: {to_table: :locations, on_delete: :nullify}
      end
    end
  end
end
