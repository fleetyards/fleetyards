# frozen_string_literal: true

class RaffleMailer < ApplicationMailer
  REDEEM_URL = "https://robertsspaceindustries.com/en/pledge/redeem-code"

  # The winner's link to claim the prize. Made here rather than passed in, so
  # it never sits in a job's arguments.
  def claim(entry)
    @entry = entry
    @raffle = entry.raffle
    @username = entry.display_username
    @claim_url = "#{FRONTEND_ENDPOINT}#{Rails.application.routes.url_helpers.frontend_raffle_claim_path(entry.generate_token_for(:raffle_claim))}"

    I18n.with_locale(recipient_locale(entry)) do
      mail(to: entry.recipient_email, subject: I18n.t(:"mailer.raffle.claim.subject", raffle: @raffle.localized_title))
    end
  end

  # The gift code, sent once the winner followed the claim link.
  def prize(entry)
    @entry = entry
    @raffle = entry.raffle
    @username = entry.display_username
    @code = @raffle.code
    @redeem_url = REDEEM_URL

    I18n.with_locale(recipient_locale(entry)) do
      mail(to: entry.recipient_email, subject: I18n.t(:"mailer.raffle.prize.subject", raffle: @raffle.localized_title))
    end
  end

  # The jobs that send these run outside any request, so nothing else picks
  # the winner's language. An entry whose account is gone falls back to English.
  private def recipient_locale(entry)
    entry.user&.notification_locale || I18n.default_locale
  end
end
