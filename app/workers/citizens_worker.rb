# frozen_string_literal: true

require 'rsi_orgs_loader'

class CitizensWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['FLEETS_LOADER_QUEUE'] || 'fleetyards_citizens_loader').to_sym

  def perform
    User.find_each do |user|
      success, citizen = RsiOrgsLoader.new.fetch_citizen(user.rsi_handle)
      next unless success

      user.update(rsi_orgs: citizen.orgs)
    end
  end
end
