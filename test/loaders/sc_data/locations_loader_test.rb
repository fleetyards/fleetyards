# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class LocationsLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree
      include ActiveJob::TestHelper

      setup do
        GameMissionLocation.delete_all
        LocationBuild.delete_all
        Location.delete_all
      end

      def loader
        fixture_loader(::ScData::Loader::LocationsLoader)
      end

      def default_loader
        loader.tap { |instance| instance.define_singleton_method(:default_environment?) { true } }
      end

      test "#all loads every place with a current build" do
        loader.all

        assert_equal 16, Location.count
        assert_equal Location.count, LocationBuild.current(fixture_source).distinct.count(:location_id)

        slugs = Location.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size
      end

      test "#all loads a place's position as a fact of the build" do
        loader.all

        planet = Location.find_by!(sc_key: "Stanton1")

        assert_equal [12_850_457_093.0, 0.0, 0.0], planet.position
        assert_equal planet.position, planet.builds.sole.position
        assert_equal 1_000_000.0, planet.radius
        assert_nil Location.find_by!(sc_key: "StantonSolarSystem").position
      end

      def surface(sc_key, environment = fixture_environment)
        Location.find_by!(sc_key:).surfaces.find_by(environment:)
      end

      def fixture_environment
        loader.sc_environment
      end

      test "#all attaches the starmap images the parse carried for a body, for its environment" do
        loader.all

        hurston = surface("Stanton1")

        assert_equal "ui_sm_stanton_1_hurston.webp", hurston.texture.filename.to_s
        assert_equal "stanton1_global_elev.png", hurston.elevation.filename.to_s
        assert_equal "stanton1_clouds_global.webp", hurston.clouds.filename.to_s
        refute hurston.ground.attached?
        assert_nil surface("StantonSolarSystem")
      end

      test "#all keeps an image's blob when a load finds the same file" do
        loader.all
        blob = surface("Stanton1").texture.blob

        loader.all

        assert_equal blob, surface("Stanton1").texture.blob
      end

      test "#all removes an image the export no longer names" do
        loader.all
        stale = surface("Stanton1")
        stale.ground.attach(io: StringIO.new("stale"), filename: "stale.webp", content_type: "image/webp")

        perform_enqueued_jobs { loader.all }

        refute stale.reload.ground.attached?
        assert stale.texture.attached?
      end

      test "#all keeps each environment's images apart" do
        hurston = create(:location, sc_key: "Stanton1", name: "Hurston", kind: "planet")
        other = hurston.surfaces.create!(environment: "elsewhere")
        other.texture.attach(io: StringIO.new("other"), filename: "other.webp", content_type: "image/webp")

        loader.all

        assert_equal "other.webp", other.reload.texture.filename.to_s
        assert_equal "ui_sm_stanton_1_hurston.webp", surface("Stanton1").texture.filename.to_s
      end

      test "#all loads a place's hangars and pads as a fact of the build" do
        loader.all

        spaceport = Location.find_by!(sc_key: "Stanton1_Lorville_Spaceport")

        assert_equal "spaceport", spaceport.kind
        assert_equal "Stanton1_Lorville", spaceport.parent.sc_key
        assert_equal [3, 2], spaceport.facilities["hangars"].pluck("count")
        assert_equal spaceport.facilities, spaceport.builds.sole.facilities
        assert_nil Location.find_by!(sc_key: "Stanton1_Lorville").facilities
      end

      test "#all loads what the starmap lists a place as offering as a fact of the build" do
        loader.all

        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        assert_equal %w[vehicle_services hospital], lorville.amenities
        assert_equal lorville.amenities, lorville.builds.sole.amenities
        assert_equal [], Location.find_by!(sc_key: "Stanton1").amenities
      end

      test "#all loads a place's armistice and restricted areas as facts of the build" do
        loader.all

        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        assert_equal "whole", lorville.armistice
        assert lorville.restricted_areas
        assert_equal "whole", lorville.builds.sole.armistice
        assert_nil Location.find_by!(sc_key: "Stanton1").armistice
        assert_nil Location.find_by!(sc_key: "Stanton1").restricted_areas
      end

      test "#all nests a place where it is and keeps the game's map parent beside it" do
        loader.all

        levski = Location.find_by!(sc_key: "Nyx_Levski")

        assert_equal ["Nyx System", "Nyx", "Delamar"], levski.ancestors.map(&:name).reverse
        assert_equal "NyxStar", levski.map_parent.sc_key
        assert_equal "NyxSolarSystem", levski.system.sc_key
        assert_predicate levski, :always_shown
      end

      test "#all leaves the map parent empty where it is the parent" do
        loader.all

        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        assert_equal "Stanton1", lorville.parent.sc_key
        assert_nil lorville.map_parent
        assert_predicate lorville, :shown_with_parent_only
      end

      # Both Outpost 54 facilities sit on Aberdeen, so the parent does not tell
      # them apart and the second one takes its key.
      test "#all tells places that share a name apart by their parent, then their key" do
        loader.all

        slugs = Location.where(name: "Outpost 54").order(:sc_key).pluck(:slug)

        assert_equal ["outpost-54-aberdeen", "outpost-54-miningfacility-stanton1b-sloane"], slugs
        assert_equal "lorville", Location.find_by!(sc_key: "Stanton1_Lorville").slug
      end

      # A namesake arriving in a later build, or in a ptu tree that shares these
      # rows, takes the longer slug and leaves the incumbent's URL alone.
      test "#all keeps a place's slug when a namesake appears" do
        loader.all
        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")

        newcomer = create(:location, name: "Lorville", parent: Location.find_by!(sc_key: "Stanton1b"))
        loader.all

        assert_equal "lorville", lorville.reload.slug
        assert_equal "lorville-aberdeen", newcomer.slug
      end

      test "#all gives a place a new slug when its name no longer reads like the old one" do
        loader.all
        lorville = Location.find_by!(sc_key: "Stanton1_Lorville")
        lorville.update_columns(slug: "lorville-central")

        lorville.update!(name: "Lorville")

        assert_equal "lorville", lorville.slug
      end

      # A terminal holds one place for every environment, so only a load of
      # the one readers get by default may move it.
      test "#all relinks terminals only on a load of the default environment" do
        olisar = create(:location, name: "Port Olisar")
        terminal = create(:terminal, location: olisar)

        loader.all
        assert_equal olisar.id, terminal.reload.location_id

        loader.tap { |instance| instance.define_singleton_method(:default_environment?) { true } }.all
        assert_nil terminal.reload.location_id
      end

      test "#all is idempotent" do
        loader.all
        slugs = Location.order(:sc_key).pluck(:sc_key, :slug, :parent_id, :map_parent_id)

        second = loader
        second.all

        assert_equal slugs, Location.order(:sc_key).pluck(:sc_key, :slug, :parent_id, :map_parent_id)
        assert_equal 0, second.stats[Location.name][:created]
        assert_equal 0, second.stats[Location.name][:updated]
      end

      test "#all retires a place the build dropped" do
        loader.all

        dropped = create(:location, sc_key: "Gone_Station", version: ::ScData::Source.version)

        loader.all

        assert_nil dropped.reload.version
        assert_predicate Location.find_by!(sc_key: "Nyx_Levski").version, :present?
      end

      test "#all on an empty tree retires nothing" do
        loader.all

        empty_tree_loader(::ScData::Loader::LocationsLoader).all

        assert_equal 16, Location.where.not(version: nil).count
      end
    end
  end
end
