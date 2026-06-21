# frozen_string_literal: true

require "discord/new_supporter"

module Notifications
  class NewPatronJob < Notifications::BaseJob
    def perform(supporter_contribution_id)
      supporter = SupporterContribution.find_by(id: supporter_contribution_id)
      return if supporter.nil? || !supporter.patreon?

      Discord::NewSupporter.new(supporter:).run
      AdminMailer.new_supporter(supporter).deliver_later
    end
  end
end
