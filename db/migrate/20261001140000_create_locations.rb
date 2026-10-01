# frozen_string_literal: true

# Places a reader can open, loaded from the game's starmap: systems, stars,
# planets, moons, stations, cities, outposts and the rest.
#
# The fact columns are mirrored from `location_builds` for the reason
# `game_missions` mirrors `game_mission_builds`: a place the export drops keeps
# describing itself off the row, and `all_facts_join` reads
# `COALESCE(b.fact, p.fact)` with `p` being this table.
#
# The parent is the row's rather than a build's. It is resolved from the tree
# a load reads, and a link that moved between builds is still one place under
# another -- there is no history worth asking about it.
class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations, id: :uuid do |t|
      # The record key, `StarMapObject.<key>`. A place merged from copies keeps
      # the first one's.
      t.string :sc_key, null: false
      # Every record the place came from. One for nearly all of them; twelve
      # for MT OpCenter TLI-4, whose copies the overrides merge.
      t.text :sc_refs, null: false, default: [], array: true
      t.string :slug, null: false

      t.string :name
      t.text :description
      t.string :kind
      t.string :game_type

      t.references :parent, type: :uuid, foreign_key: {to_table: :locations, on_delete: :nullify}
      # The game's own parent, when it is not the place this one sits in:
      # Levski is drawn under the Nyx star while it sits inside Delamar.
      t.references :map_parent, type: :uuid, foreign_key: {to_table: :locations, on_delete: :nullify}
      t.references :system, type: :uuid, foreign_key: {to_table: :locations, on_delete: :nullify}

      t.boolean :shown_on_starmap, null: false, default: false
      t.boolean :shown_with_parent_only, null: false, default: false
      t.boolean :always_shown, null: false, default: false
      t.boolean :quantum_travel_destination, null: false, default: false

      t.text :mission_template_refs, null: false, default: [], array: true

      t.string :version

      t.timestamps
    end

    add_index :locations, :sc_key, unique: true
    add_index :locations, :slug, unique: true
    add_index :locations, :sc_refs, using: :gin
    add_index :locations, :mission_template_refs, using: :gin
    add_index :locations, :version
    add_index :locations, :name

    create_table :location_builds, id: :uuid do |t|
      t.references :location, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :environment, null: false
      t.string :version, null: false

      t.string :name
      t.text :description
      t.string :kind
      t.string :game_type

      t.boolean :shown_on_starmap, null: false, default: false
      t.boolean :shown_with_parent_only, null: false, default: false
      t.boolean :always_shown, null: false, default: false
      t.boolean :quantum_travel_destination, null: false, default: false

      t.timestamps
    end

    add_index :location_builds, [:location_id, :environment, :version], unique: true, name: "index_location_builds_on_location_and_build"
    add_index :location_builds, [:environment, :version]
    add_index :location_builds, [:environment, :name]
  end
end
