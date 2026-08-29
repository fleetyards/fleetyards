# frozen_string_literal: true

require "test_helper"

module Maintenance
  class DropChangelessVersionsTaskTest < ActiveSupport::TestCase
    setup do
      PaperTrail::Version.delete_all

      @fleet = create(:fleet, created_by: create(:user).id)
      @fleet.update!(description: "A crew")
      @real = @fleet.versions.last
      @changeless = changeless_version_for(@fleet)
    end

    # An accidental run has to report rather than destroy, so the safe mode is
    # the one you get by not choosing.
    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::DropChangelessVersionsTask.new, :dry_run
    end

    test "#process leaves every row in place on a dry run" do
      assert_no_difference -> { PaperTrail::Version.count } do
        run_task(dry_run: true)
      end
    end

    test "#process reports what it would do on a dry run" do
      output = run_task(dry_run: true)

      assert_includes output, "Fleet: 1 changeless of #{PaperTrail::Version.where(item_type: "Fleet").count}"
      assert_includes output, "changeless versions: 1 of #{PaperTrail::Version.count}"
      assert_includes output, "dry run"
    end

    test "#process drops the changeless version when the dry run is turned off" do
      assert_difference -> { PaperTrail::Version.count }, -1 do
        run_task(dry_run: false)
      end

      assert_nil PaperTrail::Version.find_by(id: @changeless.id)
    end

    test "#process drops every changeless version, not just the first" do
      3.times { changeless_version_for(@fleet) }

      assert_difference -> { PaperTrail::Version.count }, -4 do
        run_task(dry_run: false)
      end

      assert_empty ::Maintenance::DropChangelessVersionsTask.changeless
    end

    test "#process keeps a version that recorded changes" do
      run_task(dry_run: false)

      assert PaperTrail::Version.exists?(@real.id)
      assert_equal [nil, "A crew"], @real.reload.changeset["description"]
    end

    # A create or destroy always carries a changeset, so one arriving without is
    # a row the task does not recognise and must not remove.
    test "#process keeps a changeless version that is not an update" do
      creation = @fleet.versions.find_by(event: "create")
      creation.update_columns(object_changes: nil)

      run_task(dry_run: false)

      assert PaperTrail::Version.exists?(creation.id)
    end

    # The pre-json column holds history that predates the migration.
    test "#process keeps a version whose changes are in the legacy column" do
      @changeless.update_columns(old_object_changes: "---\ndescription:\n- \n- A crew\n")

      assert_no_difference -> { PaperTrail::Version.count } do
        run_task(dry_run: false)
      end
    end

    # What a `touch` leaves behind: the snapshot is written, the changeset is not.
    private def changeless_version_for(record)
      PaperTrail::Version.create!(
        item_type: record.class.name,
        item_id: record.id,
        event: "update",
        object: record.attributes
      )
    end

    private def run_task(dry_run:)
      task = ::Maintenance::DropChangelessVersionsTask.new
      task.dry_run = dry_run

      capture_io { task.process }.first
    end
  end
end
