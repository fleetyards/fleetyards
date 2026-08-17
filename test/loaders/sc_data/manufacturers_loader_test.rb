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

      # The export ships several codes per company and the by-code and by-name
      # lookups only match a row without a ref, so a second code used to create a
      # second row -- four of them ended up called "Aegis Dynamics".
      test "#all leaves no two manufacturers sharing a name" do
        @loader.all

        assert_empty Manufacturer.where.not(name: nil).group(:name).having("count(*) > 1").count
      end

      # The slug is the stricter of the two: names that differ only in case or
      # punctuation pass a by-name check and still collide here.
      test "#all leaves no two manufacturers sharing a slug" do
        @loader.all

        assert_empty Manufacturer.where.not(slug: nil).group(:slug).having("count(*) > 1").count
      end

      test "#all reuses the manufacturer a second code names rather than adding one" do
        existing = create(:manufacturer, name: "Sakura Sun", code: "SASU", sc_ref: "already-here")

        @loader.all

        assert_equal [existing.id], Manufacturer.where(name: "Sakura Sun").ids
      end

      # An exact name is not the only way the table already holds a manufacturer.
      # A row whose name differs from the export's only in case slugs to the same
      # thing, so creating a second one puts two rows behind one public
      # identifier -- and, once the slug is unique in the database, fails the
      # import outright.
      test "#all reuses a manufacturer whose name differs only in case" do
        existing = create(:manufacturer, name: "SAKURA SUN", code: "SASU", sc_ref: "already-here")

        @loader.all

        assert_equal [existing.id], Manufacturer.where(slug: "sakura-sun").ids
      end

      test "#all reuses a manufacturer whose name differs only by a trailing space" do
        existing = create(:manufacturer, name: "Sakura Sun ", code: "SASU", sc_ref: "already-here")

        @loader.all

        assert_equal [existing.id], Manufacturer.where(slug: "sakura-sun").ids
      end

      # ROO and SASU are both Sakura Sun: whichever loads second must not take
      # the column over, or the two spend every import trading it.
      test "#all leaves an existing sc_ref alone when a second code matches by name" do
        existing = create(:manufacturer, name: "Sakura Sun", code: "SASU", sc_ref: "already-here")

        @loader.all

        assert_equal "already-here", existing.reload.sc_ref
      end

      # ROO names no logo where SASU names Sakura Sun's, so following the export
      # unconditionally would drop the picture depending on load order.
      test "#all keeps the icon when the record that matches names none" do
        existing = create(
          :manufacturer,
          name: "Sakura Sun", code: "SASU", sc_ref: "already-here",
          icon: "ui/sharedassets/manufacturerlogos/sakurasun_256.tif"
        )

        @loader.all

        assert_equal "ui/sharedassets/manufacturerlogos/sakurasun_256.tif", existing.reload.icon
      end

      test "#all skips the records the overrides drop" do
        @loader.all

        assert_empty Manufacturer.where(code: %w[TRAS GHEX])
      end

      test "#all loads the corrected name for a record the export mislabels" do
        @loader.all

        assert_equal "maxOx", Manufacturer.find_by(code: "MXOX").name
        assert_equal "Preacher Armaments", Manufacturer.find_by(code: "PRAR").name
        assert_equal ["AEG"], Manufacturer.where(name: "Aegis Dynamics").pluck(:code)
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

        assert_difference -> { Manufacturer.count }, 93 do
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
