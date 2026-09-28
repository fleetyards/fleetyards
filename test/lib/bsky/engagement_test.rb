# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "bsky/engagement"

module Bsky
  class EngagementTest < ActiveSupport::TestCase
    # WebMock normalises a query the nested way by default, which folds the
    # repeated `uris=` down to its last value before any matcher sees it.
    setup do
      @notation = WebMock::Config.instance.query_values_notation
      WebMock::Config.instance.query_values_notation = :flat_array
    end

    teardown do
      WebMock::Config.instance.query_values_notation = @notation
    end

    def post(uri, likes: 0, reposts: 0, replies: 0, quotes: 0)
      {uri:, likeCount: likes, repostCount: reposts, replyCount: replies, quoteCount: quotes}
    end

    def stub_posts(uris, posts)
      stub_request(:get, "#{Bsky::Engagement::ENDPOINT}?#{uris.map { |uri| "uris=#{uri}" }.join("&")}")
        .to_return(status: 200, body: {posts:}.to_json, headers: {"Content-Type" => "application/json"})
    end

    test "#fetch returns the four counts of a single post" do
      stub_posts(["at://1"], [post("at://1", likes: 4, reposts: 2, replies: 1, quotes: 3)])

      assert_equal(
        {"likes" => 4, "reposts" => 2, "replies" => 1, "quotes" => 3},
        Bsky::Engagement.new.fetch(["at://1"])
      )
    end

    # Each part of a thread is a reply to the one before it; those are ours,
    # not engagement.
    test "#fetch sums a thread and takes its own chain out of the replies" do
      uris = ["at://1", "at://2", "at://3"]
      stub_posts(uris, [
        post("at://1", likes: 5, replies: 2),
        post("at://2", likes: 1, replies: 1),
        post("at://3", likes: 1, replies: 0)
      ])

      counts = Bsky::Engagement.new.fetch(uris)

      assert_equal 7, counts["likes"]
      assert_equal 1, counts["replies"]
    end

    test "#fetch asks for at most 25 posts per request" do
      uris = (1..30).map { |n| "at://#{n}" }
      first = stub_posts(uris.first(25), uris.first(25).map { |uri| post(uri, likes: 1) })
      second = stub_posts(uris.drop(25), uris.drop(25).map { |uri| post(uri, likes: 1) })

      assert_equal 30, Bsky::Engagement.new.fetch(uris)["likes"]
      assert_requested first
      assert_requested second
    end

    test "#fetch raises when the AppView refuses" do
      stub_request(:get, /#{Regexp.escape(Bsky::Engagement::ENDPOINT)}/o).to_return(status: 502, body: "bad gateway")

      assert_raises(Bsky::Engagement::Error) { Bsky::Engagement.new.fetch(["at://1"]) }
    end

    test "#fetch is nil for a delivery with no posts" do
      assert_nil Bsky::Engagement.new.fetch([])
    end
  end
end
