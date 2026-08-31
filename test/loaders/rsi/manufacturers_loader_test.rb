# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "support/hangar_import_fixtures"

module Rsi
  class ManufacturersLoaderTest < ActiveSupport::TestCase
    include HangarImportFixtures

    LOGO = File.binread("test/fixtures/files/test.png")

    setup do
      clean_loader_tables
      @loader = ::Rsi::ManufacturersLoader.new
      @matrix = JSON.parse(File.read("test/fixtures/rsi/matrix.json")).fetch("data")
    end

    test "#one creates a manufacturer from the matrix entry" do
      manufacturer = @loader.one(data_for("RSI"))

      assert_equal 1, manufacturer.rsi_id
      assert_equal "RSI", manufacturer.code
      assert_equal "the Aurora and the Constellation", manufacturer.known_for
      assert_predicate manufacturer.description, :present?
    end

    test "#one fills only what the record is missing" do
      existing = create(
        :manufacturer,
        name: "Roberts Space Industries",
        code: "RSI",
        rsi_id: nil,
        known_for: nil,
        description: "Curated"
      )

      assert_no_difference -> { Manufacturer.count } do
        @loader.one(data_for("RSI"))
      end

      existing.reload

      assert_equal 1, existing.rsi_id
      assert_equal "the Aurora and the Constellation", existing.known_for
      assert_equal "Curated", existing.description
    end

    test "#one attaches the logo for a relative source url" do
      @loader.stubs(:fetch_images?).returns(true)

      stub_request(:get, "https://robertsspaceindustries.com/media/tb6ui8j38wwscr/source/RSI.png")
        .to_return(status: 200, body: LOGO)

      manufacturer = @loader.one(data_for("RSI"))

      assert_predicate manufacturer.logo, :attached?
      assert_equal "RSI.png", manufacturer.logo.blob.filename.to_s
    end

    # The matrix names the media host outright for five of its nineteen
    # manufacturers, which used to be prefixed with the site root.
    test "#one attaches the logo for an absolute source url" do
      @loader.stubs(:fetch_images?).returns(true)

      stub_request(:get, "https://media.robertsspaceindustries.com/s5p49a11la7y6/source.png")
        .to_return(status: 200, body: LOGO)

      manufacturer = @loader.one(data_for("ESPR"))

      assert_predicate manufacturer.logo, :attached?
    end

    test "#one leaves an overridden logo alone" do
      create(:manufacturer, name: "Roberts Space Industries", code: "RSI", rsi_id: 1, logo_overridden: true)

      @loader.stubs(:fetch_images?).returns(true)

      request = stub_request(:get, "https://robertsspaceindustries.com/media/tb6ui8j38wwscr/source/RSI.png")
        .to_return(status: 200, body: LOGO)

      manufacturer = @loader.one(data_for("RSI"))

      assert_not_requested request
      assert_not_predicate manufacturer.logo, :attached?
    end

    test "#one does not re-attach an unchanged logo" do
      stub_request(:get, "https://robertsspaceindustries.com/media/tb6ui8j38wwscr/source/RSI.png")
        .to_return(status: 200, body: LOGO)

      @loader.stubs(:fetch_images?).returns(true)
      manufacturer = @loader.one(data_for("RSI"))
      blob_id = manufacturer.logo.blob.id

      # A second run, where the file the site serves is the one already
      # attached.
      later = ::Rsi::ManufacturersLoader.new
      later.stubs(:fetch_images?).returns(true)
      later.one(data_for("RSI"))

      assert_equal blob_id, manufacturer.reload.logo.blob.id
    end

    # A matrix run reaches this once per ship, so the fetch has to happen once
    # per run rather than once per ship.
    test "#one fetches the logo once per run" do
      @loader.stubs(:fetch_images?).returns(true)

      request = stub_request(:get, "https://robertsspaceindustries.com/media/tb6ui8j38wwscr/source/RSI.png")
        .to_return(status: 200, body: LOGO)

      3.times { @loader.one(data_for("RSI")) }

      assert_requested request, times: 1
    end

    private def data_for(code)
      @matrix.find { |model| model.dig("manufacturer", "code") == code }.fetch("manufacturer")
    end
  end
end
