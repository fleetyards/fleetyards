# frozen_string_literal: true

module Raffles
  # Mails the current winner the link they claim the prize with.
  #
  # The link is made here, inside the mail, and not passed in: job arguments
  # sit readable in Redis until the job runs, and the link is what hands out
  # the code.
  class ClaimMailJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "mailers"

    def perform(entry_id)
      entry = RaffleEntry.find_by(id: entry_id)
      return if entry.blank? || !entry.claimable? || entry.claim_mail_status.present?

      mail = RaffleMailer.claim(entry).deliver_now
      entry.update!(claim_mail_status: "sent", claim_mail_message_id: Raffles::Mailing.message_id(mail))
    end
  end
end
