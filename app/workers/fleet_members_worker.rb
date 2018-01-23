# frozen_string_literal: true

require 'rsi_orgs_loader'

class FleetMembersWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['FLEETS_LOADER_QUEUE'] || 'fleetyards_fleets_loader').to_sym

  def perform(id)
    fleet = Fleet.find(id)

    members = RsiOrgsLoader.new.fetch_members(fleet.sid.downcase, fleet.member_count.to_i)

    fleet.update(rsi_members: members)
  end
end
