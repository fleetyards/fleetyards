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
      Model.find_each { |model| write(model, stock_slots(model), source) }

      fleetyards_loadouts.find_each { |loadout| write(loadout, loadout.slots, source) }
    end
  end

  def self.refresh_model(model)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) do
        write(model, stock_slots(model), source)

        fleetyards_loadouts.where(vehicles: {model_id: model.id}).find_each do |loadout|
          write(loadout, loadout.slots, source)
        end
      end
    end
  end

  def self.refresh_loadout(loadout)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) { write(loadout, loadout.slots, source) }
    end
  end

  def self.fleetyards_loadouts
    VehicleLoadout.kind_fleetyards.joins(:vehicle).includes(:items, vehicle: :model)
  end

  # A ship as it comes has its stock modules fitted, which a loadout fits by
  # choice or not at all.
  def self.stock_slots(model)
    modules = ModuleHardpoint.stock_modules(model).map do |slot, model_module_id|
      {slot_path: slot, item_type: "ModelModule", item_id: model_module_id}
    end

    LoadoutSlots.new(model, modules)
  end

  def self.write(fitting, slots, source)
    weapons = LoadoutWeapons.new(slots)

    upsert(
      {
        fitting_type: fitting.class.base_class.name,
        fitting_id: fitting.id,
        environment: source.environment,
        version: source.version,
        max_weapon_size: weapons.max_size,
        weapon_sizes: weapons.sizes
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
