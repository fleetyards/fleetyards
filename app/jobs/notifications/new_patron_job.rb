# frozen_string_literal: true

require "discord/new_supporter"

module Notifications
  class NewPatronJob < Notifications::BaseJob
    def perform(supporter_contribution_id)
      supporter = SupporterContribution.find_by(id: supporter_contribution_id)
      return if supporter.nil? || !supporter.patreon?

      AdminMailer.new_supporter(supporter).deliver_later

      begin
        Discord::NewSupporter.new(supporter:).run
      rescue => e
        Appsignal.report_error(e)
      end
    end
  end
end
