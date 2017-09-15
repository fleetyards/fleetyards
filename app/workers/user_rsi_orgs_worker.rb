# frozen_string_literal: true

require "rsi_orgs_loader"

class UserRsiOrgsWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['RSI_ORGS_QUEUE'] || 'fleetyards_rsi_orgs_loader').to_sym

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.blank?

    RsiOrgsLoader
      .new
      .for_citizen(user)
  end
end
