# frozen_string_literal: true

module Raffles
  # Asks Postmark how each raffle mail still marked `sent` fared, so the admin
  # can see a bounced claim mail while there is still time to reach the winner
  # another way.
  class MailStatusJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "default"

    def perform
      return unless Raffles::Mailing.configured?

      RaffleEntry.mail_status_pending.find_each do |entry|
        %w[claim prize].each do |kind|
          next unless entry["#{kind}_mail_status"] == "sent" && entry["#{kind}_mail_message_id"].present?

          status = Raffles::Mailing.status_for(entry["#{kind}_mail_message_id"])
          entry.update!("#{kind}_mail_status" => status) if status
        rescue Postmark::Error => error
          Appsignal.report_error(error)
        end
      end
    end
  end
end
