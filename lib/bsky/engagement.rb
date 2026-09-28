# frozen_string_literal: true

require "faraday"

module Bsky
  # Likes, reposts, replies and quotes for a thread, read from the public
  # AppView. No session: the counts are public, and the app password is kept
  # for posting.
  class Engagement
    class Error < StandardError; end

    ENDPOINT = "https://public.api.bsky.app/xrpc/app.bsky.feed.getPosts"

    # getPosts takes at most 25 URIs per call.
    BATCH_SIZE = 25

    TIMEOUT = 10
    OPEN_TIMEOUT = 5

    COUNTS = {
      "likes" => "likeCount",
      "reposts" => "repostCount",
      "replies" => "replyCount",
      "quotes" => "quoteCount"
    }.freeze

    # Summed across the thread's posts. Every post after the first is itself a
    # reply to the one before it, so the thread's own chain is taken back out of
    # the replies -- a three-part thread nobody answered has no replies.
    def fetch(uris)
      return nil if uris.blank?

      posts = uris.each_slice(BATCH_SIZE).flat_map { |batch| get_posts(batch) }

      # getPosts leaves out what it cannot resolve. A thread with a deleted
      # post still counts what is left, but nothing at all is an outage, not
      # a thread nobody liked, and the last counts stay standing.
      raise Error, "Bluesky getPosts resolved none of #{uris.size} posts" if posts.empty?

      counts = COUNTS.transform_values { |field| posts.sum { |post| post[field].to_i } }
      counts["replies"] = [counts["replies"] - (posts.size - 1), 0].max
      counts
    end

    private def get_posts(uris)
      response = connection.get(ENDPOINT, {uris:})

      raise Error, "Bluesky getPosts failed: #{response.status} #{response.body}" unless response.status.between?(200, 299)

      JSON.parse(response.body.to_s).fetch("posts", [])
    rescue JSON::ParserError
      raise Error, "Bluesky getPosts returned no JSON: #{response.status}"
    end

    private def connection
      # The flat encoder repeats `uris=` per post. The default nested one
      # writes `uris[]=`, which XRPC does not read as a list, and collapses a
      # repeated key in a hand-built query string down to its last value.
      @connection ||= Faraday.new(request: {timeout: TIMEOUT, open_timeout: OPEN_TIMEOUT, params_encoder: Faraday::FlatParamsEncoder}) do |c|
        c.headers["User-Agent"] = "Fleetyards (https://fleetyards.net, 1.0)"
      end
    end
  end
end
