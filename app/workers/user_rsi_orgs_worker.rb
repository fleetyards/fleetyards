# frozen_string_literal: true

require "rsi_orgs_loader"

class UserRsiOrgsWorker
  include Sidekiq::Worker
  sidekiq_options queue: (ENV['USER_RSI_ORGS_QUEUE'] || 'fleetyards_user_rsi_orgs_loader').to_sym

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.blank?

    orgs = RsiOrgsLoader.new.for_handle(user.rsi_handle)

    orgs.each_with_index do |org, index|
      affiliation = RsiAffiliation.find_or_initialize_by(rsi_org_id: org.id, user_id: user.id)
      affiliation.main = index.zero?
      affiliation.save
    end
  end
end
