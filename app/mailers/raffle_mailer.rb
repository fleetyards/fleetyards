# frozen_string_literal: true

class RaffleMailer < ApplicationMailer
  # Goes to the address the entrant had when entering, not the account's: the
  # account may be gone, and the point is to prove ownership of that address.
  def verification_code(entry, code)
    @username = entry.display_username
    @raffle = entry.raffle
    @code = code
    @discord_handle = Raffle::CONTACTS[:discord_handle]

    mail(
      to: entry.email,
      subject: I18n.t(:"mailer.raffle.verification_code.subject", raffle: @raffle.title)
    )
  end
end
