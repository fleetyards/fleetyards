# frozen_string_literal: true

class RaffleMailerPreview < ActionMailer::Preview
  def claim
    RaffleMailer.claim(entry)
  end

  def prize
    RaffleMailer.prize(entry)
  end

  private def entry
    raffle = Raffle.new(id: SecureRandom.uuid, title: "Win a Polaris", code: "ABCD-EFGH-IJKL-MNOP")
    RaffleEntry.new(
      id: SecureRandom.uuid, raffle:, username: "Commander", email: "commander@example.com",
      won_at: Time.current, claim_deadline_at: 3.days.from_now
    )
  end
end
