# frozen_string_literal: true

# What a berth is built for, as opposed to what could be crammed into it: how
# many of a class it takes.
#
# Entries under one dock are alternatives. The Kraken's deck is one large pad
# *or* two mediums; the Ironclad Assault's grid is six Ursas *or* two Novas,
# because a Nova is 16m against a 25m deck and an Ursa 7.6m. Separate docks are
# simultaneous -- the Kraken's deck, its side pads and its hangars are all
# available at once -- so a dock stays one physical space and the alternatives
# live inside it.
#
# `quantity` rather than `count`, which would sit next to the relation's own.
#
# Two ladders, hence the column: ship classes are the game's six pad sizes, and
# vehicle classes are the curated ATLS-to-Nova ladder. A dock may carry entries
# on either or both -- a cargo grid that takes a snub and an Ursa is not an
# exotic case.
class CreateDockCapacities < ActiveRecord::Migration[8.1]
  def change
    create_table :dock_capacities, id: :uuid do |t|
      t.references :dock, type: :uuid, null: false, foreign_key: true
      t.integer :ladder, null: false
      t.string :size, null: false
      t.integer :quantity, null: false, default: 1

      # The entry the label is rendered from -- "2 medium pads". A flag rather
      # than a typed string, so it reads in all seven locales instead of
      # whichever one the admin wrote it in.
      t.boolean :display, null: false, default: false

      t.timestamps
    end

    add_index :dock_capacities, %i[dock_id ladder size], unique: true
    add_index :dock_capacities, :dock_id, unique: true, where: "display", name: "index_dock_capacities_on_one_display_per_dock"
  end
end
