# frozen_string_literal: true

# The ships a berth takes that its class does not cover.
#
# A dock says what it is built for -- three Small pads, one Ursa-class bay --
# and everything of that class or below follows from it. What does not follow is
# the exception somebody found in game: the hull that fits despite its class, or
# the one a berth was built around. Those are named here, one row per ship.
#
# Additions only. A class that fits with one exception is a different statement
# from a class that does not fit, and nobody has needed the second one yet.
class CreateDockAdditions < ActiveRecord::Migration[8.1]
  def change
    create_table :dock_additions, id: :uuid do |t|
      # Both cascade. A row is a statement about one berth and one ship, so it
      # outlives neither: without this, deleting a ship named on somebody
      # else's dock fails on the constraint rather than taking the name with
      # it -- and `dependent: :destroy` on the dock only covers the berths that
      # ship happens to own.
      t.references :dock, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :model, type: :uuid, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps
    end

    add_index :dock_additions, %i[dock_id model_id], unique: true
  end
end
