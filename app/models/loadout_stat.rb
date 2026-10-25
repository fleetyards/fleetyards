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
      # Kept for the ships loadouts are fitted to, which reuse their stock tree.
      fitted = VehicleLoadout.kind_fleetyards.joins(:vehicle).distinct.pluck("vehicles.model_id").to_set
      trees = {}
      Model.includes(:build, :last_build).find_each do |model|
        tree = FittingTree.new(model)
        trees[model.id] = tree if fitted.include?(model.id)
        write(model, tree.stock, model, source)
      end

      fleetyards_loadouts.find_each do |loadout|
        write_loadout(loadout, source, trees[loadout.vehicle.model_id])
      end
    end
  end

  # Read again in each source: a model's build is cached on the record, and the
  # pool and buff a source's figures need are that source's.
  def self.refresh_model(model)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) do
        reloaded = Model.includes(:build, :last_build).find_by(id: model.id)
        next if reloaded.nil?

        tree = FittingTree.new(reloaded)
        write(reloaded, tree.stock, reloaded, source)

        fleetyards_loadouts.where(vehicles: {model_id: model.id}).find_each do |loadout|
          write_loadout(loadout, source, tree)
        end
      end
    end
  end

  def self.refresh_loadout(loadout)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) do
        reloaded = fleetyards_loadouts.find_by(id: loadout.id)
        write_loadout(reloaded, source) if reloaded
      end
    end
  end

  def self.fleetyards_loadouts
    VehicleLoadout.kind_fleetyards.joins(:vehicle).includes(:items, vehicle: {model: %i[build last_build]})
  end

  def self.write_loadout(loadout, source, tree = nil)
    model = loadout.vehicle.model
    crafted = loadout.items.select(&:crafted?).index_by(&:slot_path)
    fitted = (tree || FittingTree.new(model)).fitted(loadout.slots, crafted)

    write(loadout, fitted, model, source)
  end

  def self.write(fitting, tree, model, source)
    weapons = LoadoutWeapons.new(tree)
    # A concept ship -- no build and no hardpoints from one -- has no figures,
    # which is not the same as carrying no guns.
    firepower = (model.facts.nil? && tree.empty?) ? LoadoutFirepower::Result.new : LoadoutFirepower.for_tree(tree, model)

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
