# frozen_string_literal: true

require "test_helper"
require "bsky/post"
require "discord/announcement"
require "x_com/post"

module Announcements
  class PostSocialJobTest < ActiveJob::TestCase
    setup do
      @announcement = create(:announcement, :social)
    end

    test "#perform posts to Discord and records the delivery" do
      ::Discord::Announcement.stubs(:configured?).returns(true)
      ::Discord::Announcement.expects(:new).with(announcement: @announcement).returns(stub(run: true))

      Announcements::PostSocialJob.new.perform(@announcement.id, "discord")

      delivery = @announcement.delivery_for(:discord).reload
      assert delivery.status_succeeded?
      assert_equal 1, delivery.attempts
    end

    test "#perform keeps the Bluesky post's AT URI" do
      ::Bsky::Post.stubs(:configured?).returns(true)
      record = ::Bsky::Post::Record.new("at://did/app.bsky.feed.post/1", "cid")
      ::Bsky::Post.expects(:new).returns(stub(create: record))

      Announcements::PostSocialJob.new.perform(@announcement.id, "bluesky")

      assert_equal "at://did/app.bsky.feed.post/1", @announcement.delivery_for(:bluesky).reload.external_id
    end

    test "#perform keeps the X post's id" do
      ::XCom::Post.stubs(:configured?).returns(true)
      ::XCom::Post.expects(:new).returns(stub(create: "1234"))

      Announcements::PostSocialJob.new.perform(@announcement.id, "x")

      assert_equal "1234", @announcement.delivery_for(:x).reload.external_id
    end

    # Every post after the first names the one before it, and the thread's root
    # stays the first throughout -- pointing root at the previous post turns
    # one thread of three into two threads of two.
    test "#perform chains a Bluesky thread off its first post" do
      @announcement.update!(social_parts: ["One", "Two", "Three"])
      ::Bsky::Post.stubs(:configured?).returns(true)

      first = ::Bsky::Post::Record.new("at://1", "cid-1")
      second = ::Bsky::Post::Record.new("at://2", "cid-2")
      third = ::Bsky::Post::Record.new("at://3", "cid-3")

      client = mock
      client.expects(:create).with("One", root: nil, parent: nil).returns(first)
      client.expects(:create).with("Two", root: first, parent: first).returns(second)
      client.expects(:create).with("Three", root: first, parent: second).returns(third)
      ::Bsky::Post.expects(:new).returns(client)

      Announcements::PostSocialJob.new.perform(@announcement.id, "bluesky")

      assert_equal "at://1", @announcement.delivery_for(:bluesky).reload.external_id
    end

    test "#perform chains an X thread reply by reply" do
      @announcement.update!(social_parts: ["One", "Two"])
      ::XCom::Post.stubs(:configured?).returns(true)

      client = mock
      client.expects(:create).with("One", reply_to: nil).returns("1")
      client.expects(:create).with("Two", reply_to: "1").returns("2")
      ::XCom::Post.expects(:new).returns(client)

      Announcements::PostSocialJob.new.perform(@announcement.id, "x")

      # The first post is what addresses the thread: every reply hangs off it.
      assert_equal "1", @announcement.delivery_for(:x).reload.external_id
    end

    test "#perform skips rather than fails a channel with no credentials" do
      ::XCom::Post.stubs(:configured?).returns(false)
      ::XCom::Post.expects(:new).never

      Announcements::PostSocialJob.new.perform(@announcement.id, "x")

      delivery = @announcement.delivery_for(:x).reload
      assert delivery.status_skipped?
      assert_equal I18n.t("announcements.deliveries.not_configured"), delivery.error
    end

    test "#perform records the error when the platform rejects the post" do
      ::XCom::Post.stubs(:configured?).returns(true)
      ::XCom::Post.expects(:new).returns(stub.tap { |client| client.stubs(:create).raises(::XCom::Post::Error.new(403, "forbidden")) })
      Appsignal.stubs(:report_error)

      Announcements::PostSocialJob.new.perform(@announcement.id, "x")

      delivery = @announcement.delivery_for(:x).reload
      assert delivery.status_failed?
      assert_includes delivery.error, "403"
    end

    test "#perform ignores a missing announcement" do
      assert_nothing_raised { Announcements::PostSocialJob.new.perform(SecureRandom.uuid, "x") }
    end
  end
end
