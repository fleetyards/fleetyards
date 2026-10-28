# frozen_string_literal: true

require "test_helper"

module Raffles
  class PostSocialJobTest < ActiveSupport::TestCase
    setup do
      @raffle = create(:raffle, starts_at: 1.hour.ago, run_days: 3)
      ::Bsky::Post.stubs(:configured?).returns(true)
      Raffles::SocialPost.any_instance.stubs(:link_card).returns(nil)
    end

    test "posts the opening" do
      ::Bsky::Post.any_instance.expects(:create).with(regexp_matches(/\ANew raffle on FleetYards/), link_card: nil)

      PostSocialJob.new.perform(@raffle.id, "start")
    end

    test "posts the last day" do
      ::Bsky::Post.any_instance.expects(:create).with(regexp_matches(/\ALast day to enter/), link_card: nil)

      PostSocialJob.new.perform(@raffle.id, "last_day")
    end

    test "posts nothing for an unknown kind" do
      ::Bsky::Post.any_instance.expects(:create).never

      PostSocialJob.new.perform(@raffle.id, "winner")
    end
  end
end
