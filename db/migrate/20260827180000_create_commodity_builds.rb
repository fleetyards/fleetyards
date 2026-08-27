# frozen_string_literal: true

# What one build of the game says about a commodity, following the shape
# `equipment_builds` and `component_builds` established.
#
# The smallest of the four catalogues by a wide margin: the loader writes three
# facts. Everything else on the row is identity or comes from somewhere else
# entirely -- `uex_code` and `uex_id` are the UEX importer's, `slug` is generated,
# and `store_image` is curated, filled only while empty so a load never replaces
# an admin's upload.
#
# Nothing references a commodity, and there is no manufacturer, so this needs no
# entry in `Manufacturers::Deduplicator::ASSOCIATED_MODELS` -- unlike components.
class CreateCommodityBuilds < ActiveRecord::Migration[8.1]
  def change
    create_table :commodity_builds, id: :uuid do |t|
      # Cascade: a build says something about a commodity, and says nothing at
      # all once the commodity is gone.
      t.references :commodity, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :environment, null: false
      t.string :version, null: false

      t.string :name
      t.string :commodity_type
      t.text :description

      t.timestamps
    end

    # One row per commodity per build. Re-loading the same build updates it in
    # place; a new build adds a row beside it.
    add_index :commodity_builds, [:commodity_id, :environment, :version],
      unique: true, name: "index_commodity_builds_on_commodity_and_build"

    # The filters a browsable catalogue needs, so narrowing to one build stays a
    # join rather than a scan. Every read names an environment and a version,
    # because that pair is what `ScData::Source` hands out.
    add_index :commodity_builds, [:environment, :version]
    add_index :commodity_builds, [:environment, :commodity_type]
  end
end
