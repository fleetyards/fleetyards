# frozen_string_literal: true

require "test_helper"

module Raffles
  class MailStatusJobTest < ActiveSupport::TestCase
    test "records what Postmark reports for a sent raffle mail" do
      raffle = create(:raffle, :closed, drawn_at: 1.hour.ago)
      entry = create(:raffle_entry, :after_close, raffle:, claim_mail_status: "sent", claim_mail_message_id: "pm-1")
      Raffles::Mailing.stubs(:configured?).returns(true)
      Raffles::Mailing.stubs(:status_for).with("pm-1").returns("bounced")

      MailStatusJob.new.perform

      assert_equal "bounced", entry.reload.claim_mail_status
    end
  end
end
