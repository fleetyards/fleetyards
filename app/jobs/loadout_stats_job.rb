# frozen_string_literal: true

# Works out what fittings carry: one saved loadout, one ship with its loadouts
# after it was reloaded, or, after a load, every ship and every loadout of that
# environment, since a loadout keeps the stock parts it leaves in and the build
# can change those.
class LoadoutStatsJob
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(scope = {})
    if scope["vehicle_loadout_id"]
      loadout = VehicleLoadout.find_by(id: scope["vehicle_loadout_id"])
      LoadoutStat.refresh_loadout(loadout) if loadout&.kind_fleetyards?
    elsif scope["model_id"]
      model = Model.find_by(id: scope["model_id"])
      LoadoutStat.refresh_model(model) if model
    else
      sources(scope["environment"]).each { |source| LoadoutStat.refresh(source) }
    end
  end

  private def sources(environment)
    return ::ScData::Source.available if environment.blank?

    ::ScData::Source.available.select { |source| source.environment == environment }
  end
end
