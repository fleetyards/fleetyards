# frozen_string_literal: true

# The orgs a player earns standing with.
#
# Everything a patch can rewrite lives on the build, because live and ptu load
# separately. The ladders hang off the build too, and the cascade carries them
# away when `prune_builds` or `retire_absent_builds` drop one with `delete_all`.
class CreateFactions < ActiveRecord::Migration[8.1]
  def change
    create_table :factions, id: :uuid do |t|
      t.string :sc_ref, null: false
      t.string :sc_key, null: false
      t.string :slug, null: false
      t.string :name
      t.string :version

      t.timestamps
    end

    add_index :factions, :sc_ref, unique: true
    add_index :factions, :sc_key, unique: true
    add_index :factions, :slug, unique: true

    create_table :faction_builds, id: :uuid do |t|
      t.references :faction, type: :uuid, null: false, foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.string :name
      t.text :description
      t.boolean :lawful
      t.string :alignment
      t.string :headquarters
      t.string :founded
      t.string :leadership
      t.string :area
      t.string :focus

      t.timestamps
    end

    add_index :faction_builds, [:faction_id, :environment, :version], unique: true
    add_index :faction_builds, [:environment, :version]

    create_table :faction_ladders, id: :uuid do |t|
      t.references :faction_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: false

      t.string :key, null: false
      t.string :name, null: false
      t.integer :ceiling

      # Lowest first: `[{"name": "Neutral", "min_reputation": 0}, ...]`.
      t.jsonb :ranks, null: false, default: []

      t.integer :position, null: false

      t.timestamps
    end

    add_index :faction_ladders, [:faction_build_id, :position], unique: true
  end
end
