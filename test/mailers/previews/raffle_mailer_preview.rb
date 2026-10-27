# frozen_string_literal: true

class RaffleMailerPreview < ActionMailer::Preview
  def verification_code
    raffle = Raffle.new(title: "Win a Polaris")
    entry = RaffleEntry.new(raffle:, username: "Commander", email: "commander@example.com")

    RaffleMailer.verification_code(entry, "482913")
  end
end
