# frozen_string_literal: true

require "test_helper"
require "discord/engagement"

module Discord
  class EngagementTest < ActiveSupport::TestCase
    setup do
      @client = mock
    end

    test "#fetch merges each message's reactions by emoji" do
      parts = [
        {"index" => 0, "message_id" => "m1", "channel_id" => "c1"},
        {"index" => 1, "message_id" => "m2", "channel_id" => "c1"}
      ]
      @client.expects(:get_channel_message).with("c1", "m1").returns(
        "reactions" => [
          {"count" => 3, "emoji" => {"id" => nil, "name" => "🚀"}},
          {"count" => 1, "emoji" => {"id" => "99", "name" => "fleetyards"}}
        ]
      )
      @client.expects(:get_channel_message).with("c1", "m2").returns(
        "reactions" => [{"count" => 2, "emoji" => {"id" => nil, "name" => "🚀"}}]
      )
      @client.expects(:get_channel).with("c1").returns("guild_id" => "g1")

      engagement = Discord::Engagement.new(client: @client).fetch(parts)

      assert_equal(
        [{"emoji" => "🚀", "count" => 5}, {"emoji" => "fleetyards", "id" => "99", "count" => 1}],
        engagement["reactions"]
      )
      assert_equal "g1", engagement["guild_id"]
    end

    test "#fetch reuses a known guild id" do
      @client.expects(:get_channel_message).returns({})
      @client.expects(:get_channel).never

      engagement = Discord::Engagement.new(client: @client)
        .fetch([{"message_id" => "m1", "channel_id" => "c1"}], guild_id: "g1")

      assert_equal({"reactions" => [], "guild_id" => "g1"}, engagement)
    end

    # Posted before the webhook waited for its message: there is nothing to
    # read the reactions back from.
    test "#fetch is nil for parts that carry no message id" do
      @client.expects(:get_channel_message).never

      assert_nil Discord::Engagement.new(client: @client).fetch([{"index" => 0}])
    end

    test "#fetch skips a deleted message and a deleted custom emoji" do
      parts = [
        {"message_id" => "m1", "channel_id" => "c1"},
        {"message_id" => "m2", "channel_id" => "c1"}
      ]
      @client.expects(:get_channel_message).with("c1", "m1").returns(
        "reactions" => [
          {"count" => 2, "emoji" => {"id" => nil, "name" => "🚀"}},
          {"count" => 5, "emoji" => {"id" => "77", "name" => nil}}
        ]
      )
      @client.expects(:get_channel_message).with("c1", "m2")
        .raises(::Discord::ApiClient::Error.new(404, "Unknown Message"))

      engagement = Discord::Engagement.new(client: @client).fetch(parts, guild_id: "g1")

      assert_equal [{"emoji" => "🚀", "count" => 2}], engagement["reactions"]
    end

    test "#fetch still fails when the bot cannot read the channel" do
      @client.expects(:get_channel_message).raises(::Discord::ApiClient::Error.new(403, "Missing Access"))

      assert_raises(::Discord::ApiClient::Error) do
        Discord::Engagement.new(client: @client).fetch([{"message_id" => "m1", "channel_id" => "c1"}], guild_id: "g1")
      end
    end
  end
end
