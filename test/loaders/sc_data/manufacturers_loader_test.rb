# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require_relative "../../support/hangar_import_fixtures"

module ScData
  module Loader
    class ManufacturersLoaderTest < ActiveSupport::TestCase
      include HangarImportFixtures

      setup do
        clean_loader_tables
        @loader = ::ScData::Loader::ManufacturersLoader.new
      end

      test "#all loads data from game files" do
        initial = Manufacturer.count

        @loader.all

        assert_operator Manufacturer.count - initial, :>=, 95

        manufacturer_codes = Manufacturer.pluck(:code)
        assert_equal manufacturer_codes.uniq.size, manufacturer_codes.size
      end

      test "#all attaches the logo the parser carried over" do
        @loader.all

        logo = Manufacturer.find_by(code: "TALN").logo

        assert_predicate logo, :attached?
        assert_equal "talon_256.png", logo.filename.to_s
        assert_equal "image/png", logo.content_type
      end

      # Attaching an identical file writes a fresh blob, so a load that changed
      # nothing would leave a few hundred orphans behind on every run.
      test "#all leaves an unchanged logo attached to the blob it already had" do
        @loader.all
        blob = Manufacturer.find_by(code: "TALN").logo.blob

        assert_no_difference -> { ActiveStorage::Blob.count } do
          @loader.all
        end

        assert_equal blob, Manufacturer.find_by(code: "TALN").logo.blob
      end

      # A load cannot tell its own attachment from one an admin uploaded, and
      # the manufacturers the game names no logo for are exactly the ones
      # somebody filled in by hand -- so a blank path leaves the file alone
      # rather than taking their work with it.
      test "#all leaves an uploaded logo alone when the game names none" do
        curated = create(:manufacturer, code: "NOSUCHCODE", sc_ref: nil, icon: nil)
        curated.logo.attach(
          io: File.open(Rails.root.join("test/fixtures/files/test.png")),
          filename: "curated.png",
          content_type: "image/png"
        )

        @loader.all

        assert_predicate curated.reload.logo, :attached?
        assert_equal "curated.png", curated.logo.filename.to_s
      end

      test "#all records the logo the game names for a manufacturer" do
        @loader.all

        assert_equal "ui/sharedassets/manufacturerlogos/talon_256.tif",
          Manufacturer.find_by(code: "TALN").icon
        assert_operator Manufacturer.where.not(icon: nil).count, :>=, 100
      end

      # A curated description beats the game's, but an icon has no curated
      # counterpart -- it is a path into the export.
      test "#all fills the logo in on a manufacturer that predates it" do
        existing = create(:manufacturer, code: "TALN", sc_ref: nil, icon: nil)

        @loader.all

        assert_equal "ui/sharedassets/manufacturerlogos/talon_256.tif", existing.reload.icon
      end

      test "reuses existing entries with matrix data" do
        pledge_response_stub = File.read("test/fixtures/rsi/300i_pledge_page.html")
        matrix_response_stub = File.read("test/fixtures/rsi/matrix.json")
        rsi_models_loader = ::Rsi::ModelsLoader.new

        Timecop.freeze("2017-01-01 14:00:00")

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
          .to_return(status: 200, body: pledge_response_stub)

        stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
          .to_return(status: 200, body: matrix_response_stub)

        stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
          .to_return(status: 200, body: [{data: {store: {search: {resources: []}}}}].to_json, headers: {"Content-Type" => "application/json"})

        assert_difference -> { Manufacturer.count }, 19 do
          rsi_models_loader.all
        end

        assert_difference -> { Manufacturer.count }, 96 do
          @loader.all
        end

        manufacturer_codes = Manufacturer.pluck(:code)
        assert_equal manufacturer_codes.uniq.size, manufacturer_codes.size
      ensure
        Timecop.return
      end
    end
  end
end
