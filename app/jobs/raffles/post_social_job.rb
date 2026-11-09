# frozen_string_literal: true

require "bsky/post"

module Raffles
  # Posts a raffle's opening, its last day or its draw to Bluesky.
  #
  # `retry: false`: a retry is a duplicate post, not a second attempt.
  class PostSocialJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    def perform(raffle_id, kind = "start")
      raffle = Raffle.find_by(id: raffle_id)
      return if raffle.blank? || Raffles::SocialPost::KINDS.exclude?(kind) || !::Bsky::Post.configured?

      post = Raffles::SocialPost.new(raffle)
      text = post.text(kind, ::Announcements::Platform::BLUESKY)
      return if text.blank?

      ::Bsky::Post.new.create(text, link_card: post.link_card)
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
