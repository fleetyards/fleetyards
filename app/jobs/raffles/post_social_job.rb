# frozen_string_literal: true

require "bsky/post"

module Raffles
  # Posts a raffle's opening to Bluesky.
  #
  # `retry: false`: a retry is a duplicate post, not a second attempt.
  class PostSocialJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    def perform(raffle_id)
      raffle = Raffle.find_by(id: raffle_id)
      return if raffle.blank? || !::Bsky::Post.configured?

      post = Raffles::SocialPost.new(raffle)
      ::Bsky::Post.new.create(post.text(:start, ::Announcements::Platform::BLUESKY), link_card: post.link_card)
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
