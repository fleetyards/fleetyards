# frozen_string_literal: true

require "test_helper"

module Raffles
  class PrizeMailJobTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    setup do
      Premailer::Rails::Hook.stubs(:delivering_email)
      @raffle = create(:raffle, :closed, drawn_at: 1.hour.ago, code: "THE-GIFT-CODE")
      @entry = create(:raffle_entry, :after_close, raffle: @raffle, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)
    end

    test "mails a claimed win its code and concludes the raffle" do
      @entry.claim!

      assert_emails 1 do
        PrizeMailJob.new.perform(@entry.id)
      end

      assert_includes ActionMailer::Base.deliveries.last.to_s, "THE-GIFT-CODE"
      assert @entry.reload.prize_mail_sent_at.present?
      assert @raffle.reload.concluded?
    end

    test "sends nothing for an unclaimed win" do
      assert_no_emails { PrizeMailJob.new.perform(@entry.id) }
    end

    test "sends the code once" do
      @entry.claim!
      PrizeMailJob.new.perform(@entry.id)

      assert_no_emails { PrizeMailJob.new.perform(@entry.id) }
    end
  end
end
