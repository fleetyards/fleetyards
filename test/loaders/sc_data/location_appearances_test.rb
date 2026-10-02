# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class LocationAppearancesTest < ActiveSupport::TestCase
      setup do
        @hurston = create(:location, name: "Hurston", sc_key: "Stanton1", kind: "planet")
        @levski = create(:location, name: "Levski", sc_key: "Nyx_Levski", kind: "city")
      end

      test "#apply colours a place that has no colour yet" do
        appearances(seeds: {"Stanton1" => {"color" => "#9c846e"}}).apply

        assert_equal "#9c846e", @hurston.reload.color
      end

      test "#apply leaves a colour an admin set alone" do
        @hurston.update!(color: "#ff0000")

        assert_equal 0, appearances(seeds: {"Stanton1" => {"color" => "#9c846e"}}).apply
        assert_equal "#ff0000", @hurston.reload.color
      end

      test "#apply attaches the header picture of a place that has none" do
        appearances(seeds: {"Nyx_Levski" => {"image" => "test/fixtures/files/test.png"}}).apply

        assert_predicate @levski.reload.image, :attached?
        assert_equal "test.png", @levski.image.filename.to_s
      end

      test "#apply keeps a picture an admin uploaded" do
        @levski.image.attach(io: Rails.root.join("test/fixtures/files/test.png").open, filename: "admin.png", content_type: "image/png")

        assert_equal 0, appearances(seeds: {"Nyx_Levski" => {"image" => "test/fixtures/files/test.png"}}).apply
        assert_equal "admin.png", @levski.reload.image.filename.to_s
      end

      test "#apply leaves a seeded colour and picture an admin cleared cleared" do
        seeds = {"Nyx_Levski" => {"color" => "#4d5a63", "image" => "test/fixtures/files/test.png"}}
        appearances(seeds:).apply

        @levski.reload.update!(color: nil)
        @levski.image.purge

        assert_equal 0, appearances(seeds:).apply
        assert_nil @levski.reload.color
        assert_not @levski.image.attached?
      end

      test "#apply seeds again once the seed itself changes" do
        appearances(seeds: {"Stanton1" => {"color" => "#9c846e"}}).apply
        @hurston.reload.update!(color: nil)

        appearances(seeds: {"Stanton1" => {"color" => "#a0522d"}}).apply

        assert_equal "#a0522d", @hurston.reload.color
      end

      test "the seed file names only places by their record key, with valid colours" do
        seeds = ::ScData::Loader::LocationAppearances.seeds

        # YAML keeps the last of two entries for one key without a word.
        keys = Rails.root.join(::ScData::Loader::LocationAppearances::PATH).readlines.grep(/\A\S+:\s*\z/)
        assert_equal keys.uniq, keys

        assert_operator seeds.size, :>=, 30
        seeds.each_value do |seed|
          assert_match(/\A#\h{6}\z/, seed["color"]) if seed["color"]
          assert_predicate Rails.root.join(seed["image"]), :file? if seed["image"]
        end
      end

      private def appearances(**)
        ::ScData::Loader::LocationAppearances.new(**)
      end
    end
  end
end
