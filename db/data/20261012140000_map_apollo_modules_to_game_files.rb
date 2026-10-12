# frozen_string_literal: true

# The Apollo's six medical-bed modules came from the ship matrix without an
# `sc_key`, and the modules loader only loads a module that has one, so the game
# files' names and descriptions never reached them. The keys are the item records
# the export ships them as.
#
# A keyed module is only offered for a build it has a row for, so each one also
# gets a row for every build the table already holds, copied from the module.
# Without them the modules would vanish from both ships until the next load.
class MapApolloModulesToGameFiles < ActiveRecord::Migration[8.1]
  MODEL_NAMES = ["Apollo Medivac", "Apollo Triage"].freeze

  SC_KEYS = (1..3).flat_map { |tier|
    %w[Left Right].map { |side| ["Tier #{tier} Module #{side}", "RSI_Apollo_Module_#{side}_Tier_#{tier}"] }
  }.to_h.freeze

  # Its own copy on purpose: a migration has to keep running against the schema
  # of its own moment, not `ModelModuleBuild::FACTS` as that later becomes.
  FACTS = %i[description cargo_holds].freeze

  def up
    builds = ModelModuleBuild.distinct.pluck(:environment, :version)

    SC_KEYS.each do |name, sc_key|
      ModelModule.where(name:, sc_key: nil)
        .where(id: ModelModule.joins(:models).where(models: {name: MODEL_NAMES}).select(:id))
        .find_each do |model_module|
          model_module.update_columns(sc_key:, updated_at: Time.current)

          facts = FACTS.index_with { |fact| model_module.read_attribute(fact) }

          builds.each do |environment, version|
            model_module.builds.find_or_create_by!(environment:, version:) do |build|
              build.assign_attributes(facts)
            end
          end
        end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
