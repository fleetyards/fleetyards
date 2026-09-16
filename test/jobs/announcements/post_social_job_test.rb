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
      ::Bsky::Post.expects(:new).returns(stub(create: "at://did/app.bsky.feed.post/1"))

      Announcements::PostSocialJob.new.perform(@announcement.id, "bluesky")

      assert_equal "at://did/app.bsky.feed.post/1", @announcement.delivery_for(:bluesky).reload.external_id
    end

    test "#perform keeps the X post's id" do
      ::XCom::Post.stubs(:configured?).returns(true)
      ::XCom::Post.expects(:new).returns(stub(create: "1234"))

      Announcements::PostSocialJob.new.perform(@announcement.id, "x")

      assert_equal "1234", @announcement.delivery_for(:x).reload.external_id
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
