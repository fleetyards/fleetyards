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
      "#{@model.manufacturer.name} #{@model.name} is now on FleetYards\n#{@model.frontend_url}\n#starcitizen"
    end

    test "#perform sends discord notification and marks model as notified" do
      ::Discord::NewShip.expects(:new).with(model: @model).returns(stub(run: true))
      ::Bsky::Post.expects(:new).never

      perform

      assert_equal true, @model.reload.notified
    end

    test "#perform skips a ship hidden again before the job ran" do
      @model.update!(hidden: true)
      ::Discord::NewShip.expects(:new).never

      perform

      assert_equal false, @model.reload.notified
    end

    test "#perform posts the ship, its link and the hashtag to Bluesky" do
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client| client.expects(:create).with(expected_text, has_key(:link_card)) })

      perform
    end

    test "#perform gives the Bluesky post a link card with the store image" do
      @model.store_image.attach(io: Rails.root.join("test/fixtures/files/ship.jpg").open, filename: "ship.jpg", content_type: "image/jpeg")
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client|
        client.expects(:create).with { |_text, link_card:|
          link_card.uri == @model.frontend_url &&
            link_card.title == "#{@model.manufacturer.name} #{@model.name}" &&
            link_card.content_type == "image/webp" &&
            Marcel::MimeType.for(StringIO.new(link_card.image)) == "image/webp"
        }
      })

      perform
    end

    test "#perform posts the link card without a picture when the ship has none" do
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client|
        client.expects(:create).with { |_text, link_card:| link_card.image.nil? }
      })

      perform
    end

    test "#perform shortens the ship name, never the link or the hashtag" do
      Manufacturer.any_instance.stubs(:name).returns("X" * 400)
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).returns(mock.tap { |client|
        client.expects(:create).with { |text, **|
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
      ::Bsky::Post.expects(:new).returns(mock.tap { |client| client.expects(:create).with("#{link}\n#starcitizen", has_key(:link_card)) })

      perform
    end

    test "#perform skips a platform whose link and hashtag cannot fit" do
      Model.any_instance.stubs(:frontend_url).returns("https://fleetyards.test/#{"x" * 300}")
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.expects(:new).never

      perform

      assert_equal true, @model.reload.notified
    end

    test "#perform still marks the model notified when a platform fails" do
      ::Bsky::Post.stubs(:configured?).returns(true)
      ::Bsky::Post.stubs(:new).returns(stub.tap { |client| client.stubs(:create).raises(::Bsky::Post::Error) })
      Appsignal.expects(:report_error).with(instance_of(::Bsky::Post::Error))

      perform

      assert_equal true, @model.reload.notified
    end
  end
end
