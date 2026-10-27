# frozen_string_literal: true

require "test_helper"

class RaffleMailerTest < ActionMailer::TestCase
  setup do
    raffle = create(:raffle, :closed, title: "Win a Polaris", drawn_at: 1.hour.ago)
    @entry = create(:raffle_entry, :after_close, raffle:, email: "entered-with@example.com")
    @entry.user.update_columns(email: "current@example.com")
  end

  test "#verification_code goes to the address the entrant entered with" do
    mail = RaffleMailer.verification_code(@entry, "123456")

    assert_equal ["entered-with@example.com"], mail.to
    assert_equal I18n.t(:"mailer.raffle.verification_code.subject", raffle: "Win a Polaris"), mail.subject
  end

  test "#verification_code names the code and the Discord contact" do
    body = RaffleMailer.verification_code(@entry, "123456").html_part&.body.to_s.presence ||
      RaffleMailer.verification_code(@entry, "123456").body.to_s

    assert_includes body, "123456"
    assert_includes body, Raffle::CONTACTS[:discord_handle]
  end
end
