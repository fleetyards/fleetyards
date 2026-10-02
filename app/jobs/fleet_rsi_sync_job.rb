# frozen_string_literal: true

class FleetRsiSyncJob < ::ApplicationJob
  sidekiq_options queue: "loaders", retry: 2

  def perform(fleet_id)
    fleet = Fleet.kept.find_by(id: fleet_id)
    return if fleet.blank?

    FleetRsiSync.new(fleet).run
  end
end
