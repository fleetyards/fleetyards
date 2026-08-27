# frozen_string_literal: true

# Seeds a build row from what each model row already says, so the new table is
# populated before anything reads from it -- rather than staying empty until the
# next sc_data load.
#
# Models have no `version` column, unlike the other three catalogues, so there is
# no per-row version to key on. `in_game` stands in for it: it is set by the very
# check a build row expresses -- a parsed model file existing for this
# environment -- so a model that is in the game gets a build for the version the
# app is configured on, and one that is not gets none.
#
# The values seeded here are the game files' in all but a handful of cases: the
# sc_data loader writes these columns on every load, after the RSI loader. Where
# an admin has curated one, the curated value is what lands in the build, and the
# next load overwrites it. That is the same trade the other three catalogues
# made, and the layering question -- curated over game files over ship matrix --
# belongs to the step that moves the readers.
class BackfillModelBuilds < ActiveRecord::Migration[8.1]
  # Its own copy on purpose: a migration has to keep running against the schema of
  # its own moment, not `ModelBuild::FACTS` as that later becomes.
  FACTS = %i[
    mass hull_health hull_parts hull_doors weapon_pool_size signature_cross_section ground
    personal_inventory
    cargo_holds quantum_fuel_tanks hydrogen_fuel_tanks external_fuel_tanks refuel_boom
    scm_speed scm_speed_boosted reverse_speed_boosted max_speed
    pitch pitch_boosted yaw yaw_boosted roll roll_boosted
    ground_max_speed ground_reverse_speed ground_acceleration ground_decceleration
  ].freeze

  def up
    environment = ScData::Source.environment
    version = ScData::Source.version

    Model.where(in_game: true).find_each do |model|
      build = model.builds.find_or_initialize_by(environment:, version:)

      # `read_attribute` would hand back the raw YAML for the five serialized
      # columns, so these go through the readers -- which at this point still
      # answer from the columns, because nothing reads the build yet.
      build.update!(FACTS.index_with { |fact| model.public_send(fact) })
    end
  end

  def down
    ModelBuild.delete_all
  end
end
