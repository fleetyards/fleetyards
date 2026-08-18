# frozen_string_literal: true

require "discord/new_supporter"

module Notifications
  class NewPatronJob < Notifications::BaseJob
    def perform(supporter_contribution_id)
      supporter = SupporterContribution.find_by(id: supporter_contribution_id)
      return if supporter.nil? || !supporter.patreon?

      AdminMailer.new_supporter(supporter).deliver_later

      AdminNotification.notify!(
        type: :new_supporter,
        title: "New Patreon Supporter",
        body: "#{supporter.display_name} — #{supporter.formatted_amount}",
        link: "/supporter-contributions",
        record: supporter
      )

      begin
        ::Discord::NewSupporter.new(supporter:).run
      rescue => e
        Appsignal.report_error(e)
      end
    end
  end
end
