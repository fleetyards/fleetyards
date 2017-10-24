# frozen_string_literal: true

class FleetsWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['FLEETS_LOADER_QUEUE'] || 'fleetyards_fleets_loader').to_sym

  def perform
    Fleet.find_each do |fleet|
      fleet.fetch_rsi_org
      fleet.save
    end
  end
end
