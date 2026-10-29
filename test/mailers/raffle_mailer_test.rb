# frozen_string_literal: true

require "test_helper"

class RaffleMailerTest < ActionMailer::TestCase
  setup do
    raffle = create(:raffle, :closed, title: "Win a Polaris", code: "THE-GIFT-CODE", drawn_at: 1.hour.ago)
    @entry = create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)
  end

  test "#claim links to the claim page and leaves the code out" do
    mail = RaffleMailer.claim(@entry)

    assert_equal [@entry.recipient_email], mail.to
    assert_equal I18n.t(:"mailer.raffle.claim.subject", raffle: "Win a Polaris"), mail.subject
    assert_includes mail.body.encoded, "/raffle-claims/"
    assert_not_includes mail.body.encoded, "THE-GIFT-CODE"
  end

  test "#claim goes to the address captured at entry once the account is gone" do
    @entry.update_columns(user_id: nil, email: "entered-with@example.com")

    assert_equal ["entered-with@example.com"], RaffleMailer.claim(@entry.reload).to
  end

  test "#claim is written in the winner's language" do
    @entry.raffle.update!(translations: {"de" => {"title" => "Gewinne eine Polaris"}})
    @entry.user.update_columns(locale: "de")

    mail = RaffleMailer.claim(@entry)

    assert_equal I18n.t(:"mailer.raffle.claim.subject", raffle: "Gewinne eine Polaris", locale: :de), mail.subject
  end

  test "#prize carries the code" do
    mail = RaffleMailer.prize(@entry)

    assert_equal I18n.t(:"mailer.raffle.prize.subject", raffle: "Win a Polaris"), mail.subject
    assert_includes mail.body.encoded, "THE-GIFT-CODE"
    assert_includes mail.body.encoded, RaffleMailer::REDEEM_URL
  end
end
