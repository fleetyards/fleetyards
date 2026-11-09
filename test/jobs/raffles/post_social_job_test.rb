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

    test "posts the draw with the winner and the number of entrants" do
      raffle = create(:raffle, title: "Win a Polaris")
      user = create(:user, username: "OmegaClark")
      create(:raffle_entry, raffle:, user:)
      create(:raffle_entry, raffle:)
      raffle.update_columns(starts_at: 10.days.ago, ends_at: 1.day.ago)
      Raffles::Draw.new(raffle, admin_user: create(:admin_user)).call
      winner = raffle.current_winner.display_username

      ::Bsky::Post.any_instance.expects(:create).with(
        regexp_matches(/\AThank you to all 2 citizens who joined, and better luck next time! Congratulations to #{winner}, the winner of the FleetYards raffle: Win a Polaris\n/),
        link_card: nil
      )

      PostSocialJob.new.perform(raffle.id, "drawn")
    end

    test "posts no draw for a raffle without a winner" do
      ::Bsky::Post.any_instance.expects(:create).never

      PostSocialJob.new.perform(@raffle.id, "drawn")
    end

    test "posts nothing for an unknown kind" do
      ::Bsky::Post.any_instance.expects(:create).never

      PostSocialJob.new.perform(@raffle.id, "winner")
    end
  end
end
