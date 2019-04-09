# frozen_string_literal: true

require 'rsi_orgs_loader'

class CitizenWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['FLEETS_LOADER_QUEUE'] || 'fleetyards_citizens_loader').to_sym

  def perform(user_id)
    user = User.find(user_id)

    success, citizen = RsiOrgsLoader.new.fetch_citizen(user.rsi_handle)
    return unless success

    user.update(rsi_orgs: citizen.orgs)
  end
end
