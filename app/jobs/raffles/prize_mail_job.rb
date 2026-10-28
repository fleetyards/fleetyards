# frozen_string_literal: true

module Raffles
  # Mails a winner who claimed the prize its gift code, and ends the raffle.
  #
  # The code is read inside the mail, never passed in as an argument, for the
  # same reason the claim link is.
  class PrizeMailJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "mailers"

    def perform(entry_id)
      entry = RaffleEntry.find_by(id: entry_id)
      return if entry.blank? || entry.claimed_at.blank? || entry.prize_mail_sent_at.present?

      mail = RaffleMailer.prize(entry).deliver_now
      entry.update!(
        prize_mail_status: "sent",
        prize_mail_message_id: Raffles::Mailing.message_id(mail),
        prize_mail_sent_at: Time.current
      )
      entry.raffle.conclude!
    end
  end
end
