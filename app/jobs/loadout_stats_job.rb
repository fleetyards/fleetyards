# frozen_string_literal: true

# Works out what fittings carry: one saved loadout, or, after a load, every ship
# as it comes and every loadout, since a loadout keeps the stock parts it leaves
# in and the build can change those.
class LoadoutStatsJob
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(vehicle_loadout_id = nil)
    if vehicle_loadout_id
      loadout = VehicleLoadout.find_by(id: vehicle_loadout_id)
      LoadoutStat.refresh_loadout(loadout) if loadout&.kind_fleetyards?
    else
      ::ScData::Source.available.each { |source| LoadoutStat.refresh(source) }
    end
  end
end
