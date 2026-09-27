# frozen_string_literal: true

class AddCanLandOnPlanetsToModels < ActiveRecord::Migration[8.1]
  # Ships whose size or external cargo keeps them off planetary surfaces. No
  # game file says so, so it is curated, and set here rather than in a data
  # migration: those run after every schema migration and can't lean on
  # `Model`.
  CANNOT_LAND = %w[misc-hull-c misc-hull-d misc-hull-e aegs-javelin anvl-odin].freeze

  def up
    add_column :models, :can_land_on_planets, :boolean, default: true, null: false

    execute <<~SQL.squish
      UPDATE models SET can_land_on_planets = FALSE, updated_at = NOW()
      WHERE slug IN (#{CANNOT_LAND.map { |slug| connection.quote(slug) }.join(", ")})
    SQL
  end

  def down
    remove_column :models, :can_land_on_planets
  end
end
