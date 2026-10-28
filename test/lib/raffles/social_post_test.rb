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
  end
end
