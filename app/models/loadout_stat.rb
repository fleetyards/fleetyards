# frozen_string_literal: true

# What a fitting carries in one environment, worked out ahead of time so a
# hangar can filter and sort on it. The fitting is a model as it comes, or a
# loadout its owner saved.
#
# One row per environment rather than per build: a loadout floats with the
# build, and until the refresh after a load has run, last build's guns are a
# better answer than none.
class LoadoutStat < ApplicationRecord
  belongs_to :fitting, polymorphic: true

  def self.refresh(source = ::ScData::Source.current.served)
    ::ScData::Source.with(source) do
      Model.find_each { |model| write(model, FittingTree.stock(model), model, source) }

      fleetyards_loadouts.find_each { |loadout| write_loadout(loadout, source) }
    end
  end

  def self.refresh_model(model)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) do
        write(model, FittingTree.stock(model), model, source)

        fleetyards_loadouts.where(vehicles: {model_id: model.id}).find_each { |loadout| write_loadout(loadout, source) }
      end
    end
  end

  def self.refresh_loadout(loadout)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) { write_loadout(loadout, source) }
    end
  end

  def self.fleetyards_loadouts
    VehicleLoadout.kind_fleetyards.joins(:vehicle).includes(:items, vehicle: :model)
  end

  def self.write_loadout(loadout, source)
    model = loadout.vehicle.model
    write(loadout, FittingTree.fitted(model, loadout.slots), model, source)
  end

  def self.write(fitting, tree, model, source)
    weapons = LoadoutWeapons.new(tree)
    firepower = LoadoutFirepower.for_tree(tree, model)

    upsert(
      {
        fitting_type: fitting.class.base_class.name,
        fitting_id: fitting.id,
        environment: source.environment,
        version: source.version,
        max_weapon_size: weapons.max_size,
        weapon_sizes: weapons.sizes,
        **firepower.to_h,
        formula_version: LoadoutFirepower::VERSION
      },
      unique_by: :index_loadout_stats_on_fitting_and_environment
    )
  end

  # A source is served from its own environment, so the environment needs no
  # build resolved.
  def self.for_environment(stats, environment = ::ScData::Source.current.environment)
    stats.find { |stat| stat.environment == environment }
  end
end
