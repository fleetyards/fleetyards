# frozen_string_literal: true

require "rsi_orgs_loader"

class RsiOrgsWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['RSI_ORGS_QUEUE'] || 'fleetyards_rsi_orgs_loader').to_sym

  def perform
    RsiOrg.find_each do |org|
      RsiOrgsLoader.new.fetch(org.sid)
    end
  end
end
