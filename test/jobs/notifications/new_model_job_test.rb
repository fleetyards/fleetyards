# frozen_string_literal: true

require "test_helper"

module Notifications
  class NewModelJobTest < ActiveJob::TestCase
    setup do
      @model = create(:model, notified: false)
      ::Discord::NewShip.stubs(:new).returns(stub(run: true))
      ::Bsky::Post.stubs(:configured?).returns(false)
    end

    def perform
      ::Notifications::NewModelJob.new.perform(@model.id)
    end

    def expected_text
      "New ship added to FleetYards: #{@model.manufacturer.name} #{@model.name}\n#{@model.frontend_url}\n#starcitizen"
    end

    test "#perform sends discord notification and marks model as notified" do
      ::Discord::NewShip.expects(:new).with(model: @model).returns(stub(run: true))
      ::Bsky::Post.expects(:new).never

      perform

      assert_equal true, @model.reload.notified
    end

    test "#perform posts the ship, its link and the hashtag to Bluesky" do
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client| client.expects(:create).with(expected_text) })

      perform
    end

    test "#perform shortens the ship name, never the link or the hashtag" do
      Manufacturer.any_instance.stubs(:name).returns("X" * 400)
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client|
        client.expects(:create).with { |text|
          ::Announcements::Platform::BLUESKY.fits?(text) &&
            text.end_with?("…\n#{@model.frontend_url}\n#starcitizen")
        }
      })

      perform
    end

    test "#perform posts only the link and hashtag when the name has no room" do
      link = "https://fleetyards.test/ships/#{"x" * 256}"
      Model.any_instance.stubs(:frontend_url).returns(link)
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client| client.expects(:create).with("#{link}\n#starcitizen") })

      perform
    end

    test "#perform skips a platform whose link and hashtag cannot fit" do
      Model.any_instance.stubs(:frontend_url).returns("https://fleetyards.test/#{"x" * 300}")
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).never

      perform

      assert_equal true, @model.reload.notified
    end
  end
end
