# frozen_string_literal: true

require "test_helper"

module Maintenance
  class MoveExportLogosToIconTaskTest < ActiveSupport::TestCase
    ICON_PATH = "ui/sharedassets/manufacturerlogos/talon_256.tif"

    setup do
      Manufacturer.delete_all
    end

    # An accidental run has to report rather than move, so the safe mode is the
    # one you get by not choosing.
    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::MoveExportLogosToIconTask.new, :dry_run
    end

    test "#process moves nothing on a dry run" do
      manufacturer = stomped_manufacturer

      output = run_task(dry_run: true)

      assert_predicate manufacturer.reload.logo, :attached?
      assert_not_predicate manufacturer.icon, :attached?
      assert_includes output, "export artwork found in `logo`: 1"
      assert_includes output, "dry run"
    end

    test "#process moves the export's art onto icon and frees the logo" do
      manufacturer = stomped_manufacturer

      run_task(dry_run: false)

      assert_not_predicate manufacturer.reload.logo, :attached?
      assert_predicate manufacturer.icon, :attached?
      assert_equal File.basename(export_art), manufacturer.icon.filename.to_s
    end

    # The whole point of the task: the bucket has no versioning, so a purge here
    # would repeat the loss it exists to undo. The same blob has to survive.
    test "#process keeps the blob rather than purging it" do
      manufacturer = stomped_manufacturer
      blob = manufacturer.logo.blob

      assert_no_difference -> { ActiveStorage::Blob.count } do
        run_task(dry_run: false)
      end

      assert_equal blob, manufacturer.reload.icon.blob
      assert blob.service.exist?(blob.key), "the file behind the blob was deleted"
    end

    test "#process leaves a curated logo alone" do
      manufacturer = create(:manufacturer, code: "TALN", icon_path: ICON_PATH)
      manufacturer.logo.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.png")),
        filename: "curated.png",
        content_type: "image/png"
      )

      output = run_task(dry_run: false)

      assert_equal "curated.png", manufacturer.reload.logo.filename.to_s
      assert_includes output, "curated logos left alone: 1"
    end

    test "#process leaves a logo alone when the record names no export art" do
      manufacturer = create(:manufacturer, code: "NONE", icon_path: nil)
      manufacturer.logo.attach(
        io: File.open(export_art),
        filename: File.basename(export_art),
        content_type: "image/png"
      )

      run_task(dry_run: false)

      assert_predicate manufacturer.reload.logo, :attached?
    end

    # A manufacturer as an earlier load left it: the export's own artwork sitting
    # in `logo`, where it replaced whatever was there.
    private def stomped_manufacturer
      manufacturer = create(:manufacturer, code: "TALN", icon_path: ICON_PATH)
      manufacturer.logo.attach(
        io: File.open(export_art),
        filename: File.basename(export_art),
        content_type: "image/png"
      )
      manufacturer
    end

    private def export_art
      @export_art ||= Dir.glob(
        Rails.root.join("data/sc_data/parsed/live/icons/#{ICON_PATH.sub(/\.\w+\z/, "")}.*")
      ).first
    end

    private def run_task(dry_run:)
      task = ::Maintenance::MoveExportLogosToIconTask.new
      task.dry_run = dry_run

      capture_io { task.process }.first
    end
  end
end
