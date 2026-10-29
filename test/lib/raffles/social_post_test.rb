# frozen_string_literal: true

require "test_helper"

module Raffles
  class SocialPostTest < ActiveSupport::TestCase
    test "fits the platform and keeps the link whole" do
      raffle = create(:raffle, title: "A" * 400)

      %i[start last_day].each do |kind|
        text = SocialPost.new(raffle).text(kind, SocialPost::X)

        assert SocialPost::X.fits?(text)
        assert_includes text, raffle.frontend_url
      end
    end

    test "the link card reads item links and markup as plain text" do
      raffle = create(:raffle, description: "Win a **[*Constellation Mk V Centaurus*]**\n\nGood luck!")

      assert_equal "Win a Constellation Mk V Centaurus Good luck!", SocialPost.new(raffle).link_card.description
    end
  end
end
