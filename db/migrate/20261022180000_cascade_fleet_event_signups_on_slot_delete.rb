# frozen_string_literal: true

# A slot destroy loads its signups before it deletes the slot, so a signup that
# claims the slot in between survives the sweep and blocked the delete. The
# cascade removes it with the slot, as a destroy that came second would have.
class CascadeFleetEventSignupsOnSlotDelete < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :fleet_event_signups, :fleet_event_slots
    add_foreign_key :fleet_event_signups, :fleet_event_slots, on_delete: :cascade
  end
end
