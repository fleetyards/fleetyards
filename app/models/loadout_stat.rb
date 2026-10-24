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
      Model.find_each { |model| write(model, LoadoutSlots.new(model), source) }

      VehicleLoadout.kind_fleetyards.includes(:items, vehicle: :model).find_each do |loadout|
        write(loadout, loadout.slots, source)
      end
    end
  end

  def self.refresh_loadout(loadout)
    ::ScData::Source.available.each do |source|
      ::ScData::Source.with(source) { write(loadout, loadout.slots, source) }
    end
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

  def self.for_environment(stats, environment = ::ScData::Source.current.served.environment)
    stats.find { |stat| stat.environment == environment }
  end
end
