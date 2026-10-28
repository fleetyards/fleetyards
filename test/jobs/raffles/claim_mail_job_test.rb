# frozen_string_literal: true

require "test_helper"

module Raffles
  class ClaimMailJobTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    setup do
      Premailer::Rails::Hook.stubs(:delivering_email)
      raffle = create(:raffle, :closed, drawn_at: 1.hour.ago, code: "THE-GIFT-CODE")
      @entry = create(:raffle_entry, :after_close, raffle:, draw_position: 1, won_at: 1.hour.ago, claim_deadline_at: 2.days.from_now)
    end

    test "mails the winner a claim link and never the code" do
      assert_emails 1 do
        ClaimMailJob.new.perform(@entry.id)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal [@entry.recipient_email], mail.to
      assert_includes mail.html_part&.body.to_s.presence || mail.body.to_s, "/raffle-claims/"
      assert_not_includes mail.to_s, "THE-GIFT-CODE"
      assert_equal "sent", @entry.reload.claim_mail_status
    end

    test "sends one claim mail per win" do
      ClaimMailJob.new.perform(@entry.id)

      assert_no_emails { ClaimMailJob.new.perform(@entry.id) }
    end
  end
end
