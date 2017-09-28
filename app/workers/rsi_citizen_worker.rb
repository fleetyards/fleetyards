# frozen_string_literal: true

require "rsi_orgs_loader"

class RsiCitizenWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['RSI_CITIZENS_QUEUE'] || 'fleetyards_rsi_citizen_loader').to_sym

  def perform
    User.where.not(rsi_handle: nil).find_each do |user|
      orgs = RsiOrgsLoader.new.for_handle(user.rsi_handle)
      user.update(rsi_org: orgs.first.sid) if orgs.present?
    end
  end
end
