# frozen_string_literal: true

# The Apollo's six medical-bed modules came from the ship matrix without an
# `sc_key`, and the modules loader only loads a module that has one, so the game
# files' names and descriptions never reached them. The keys are the item records
# the export ships them as.
#
# A keyed module is only offered for a build it has a row for, so each one also
# gets a row for the build each environment serves -- both ship the six items.
# Without it the modules would vanish from both ships until the next load. The
# rows carry no facts: the module's own columns answer until a load writes them.
class MapApolloModulesToGameFiles < ActiveRecord::Migration[8.1]
  MODEL_NAMES = ["Apollo Medivac", "Apollo Triage"].freeze

  SC_KEYS = (1..3).flat_map { |tier|
    %w[Left Right].map { |side| ["Tier #{tier} Module #{side}", "RSI_Apollo_Module_#{side}_Tier_#{tier}"] }
  }.to_h.freeze

  def up
    apollo_modules = ModelModule.where(
      id: ModelModule.joins(:models).where(models: {name: MODEL_NAMES}).select(:id)
    )

    SC_KEYS.each do |name, sc_key|
      apollo_modules.where(name:, sc_key: nil).update_all(sc_key:, updated_at: Time.current)
    end

    served_builds.each do |source|
      apollo_modules.where(sc_key: SC_KEYS.values).find_each do |model_module|
        model_module.builds.find_or_create_by!(environment: source.environment, version: source.version)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  # An environment with no module builds at all offers every module, and a row
  # here would end that for all the others.
  private def served_builds
    ScData::Source.configured
      .select { |source| ModelModuleBuild.exists?(environment: source.environment) }
      .map { |source| source.served_for(ModelModuleBuild) }
  end
end
