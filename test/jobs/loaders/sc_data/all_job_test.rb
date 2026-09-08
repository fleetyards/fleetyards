# frozen_string_literal: true

require "test_helper"

module Loaders
  module ScData
    class AllJobTest < ActiveJob::TestCase
      setup do
        Rails.configuration.stubs(:sc_data).returns({sources: {live: "3.24.0"}, default: "live"})
        @admin_user = create(:admin_user, resource_access: [:models])
        AdminNotificationsChannel.stubs(:broadcast_to)
      end

      def notification
        AdminNotification.find_by(admin_user: @admin_user, notification_type: "sc_data_import")
      end

      # Without an environment the job loads the configured default, which is
      # what the admin trigger sends and what a job enqueued before the argument
      # existed carries.
      test "#perform loads the configured source when given nothing" do
        loaded = nil
        ::ScData::Loader::BaseLoader.stubs(:all).with { loaded = ::ScData::Source.current.to_s }

        ::Loaders::ScData::AllJob.new.perform

        assert_equal "3.24.0 (live)", loaded
        assert_equal "3.24.0", Imports::ScData::AllImport.last.version
      end

      # The whole load runs inside the source it was given, so every loader,
      # scope and the parsed-tree fetch underneath resolve that build without
      # being handed it -- which is what makes a second environment loadable at
      # all.
      test "#perform runs the load inside the environment it was given" do
        Rails.configuration.stubs(:sc_data).returns({
          sources: {live: "3.24.0", ptu: "3.24.1-ptu.2"}, default: "live"
        })

        loaded = nil
        ::ScData::Loader::BaseLoader.stubs(:all).with { loaded = ::ScData::Source.current.to_s }

        ::Loaders::ScData::AllJob.new.perform("3.24.1-ptu.2", nil, "ptu")

        assert_equal "3.24.1-ptu.2 (ptu)", loaded
        assert_equal "3.24.1-ptu.2", Imports::ScData::AllImport.last.version
      end

      # The source is back to what it was once the job returns: a job inside a
      # request must not strand the outer value.
      test "#perform leaves the source as it found it" do
        before = ::ScData::Source.current

        ::ScData::Loader::BaseLoader.stubs(:all)
        ::Loaders::ScData::AllJob.new.perform("3.24.1-ptu.2", nil, "ptu")

        assert_equal before, ::ScData::Source.current
      end

      test "#perform creates an import, runs the loader, and finishes the import" do
        ::ScData::Loader::BaseLoader.expects(:all)

        ::Loaders::ScData::AllJob.new.perform

        import = Imports::ScData::AllImport.last
        assert import.present?
        assert_equal "finished", import.aasm_state
      end

      # The counts are the record of what a load did. A log line is not enough:
      # the admin view of an import is where somebody looks after a build lands
      # badly, and "changed nothing" has to be distinguishable there from
      # "rewrote the catalogue".
      test "#perform keeps what each loader did on the import" do
        ::ScData::Loader::BaseLoader.expects(:all).returns({
          "EquipmentLoader" => {"Equipment" => {created: 2, updated: 1, unchanged: 4818}}
        })

        ::Loaders::ScData::AllJob.new.perform

        output = Imports::ScData::AllImport.last.output

        assert_equal({"created" => 2, "updated" => 1, "unchanged" => 4818},
          output.dig("EquipmentLoader", "Equipment"))
      end

      test "#perform reports the counts each loader produced" do
        ::ScData::Loader::BaseLoader.expects(:all).returns({
          "EquipmentLoader" => {"Equipment" => {created: 2, updated: 1, unchanged: 4818}}
        })

        ::Loaders::ScData::AllJob.new.perform

        assert_not_nil notification
        assert_equal "info", notification.severity
        assert_includes notification.title, "3.24.0"
        assert_includes notification.body, "created 2"
      end

      # The failure that left Commodity and Equipment empty for a week: the
      # loader ran, wrote nothing, and left nothing unchanged either.
      test "#perform asks for a human when a catalogue came back empty" do
        ::ScData::Loader::BaseLoader.expects(:all).returns({
          "EquipmentLoader" => {"Equipment" => {created: 0, updated: 0, unchanged: 0}}
        })

        creator = mock("GithubIssueCreator")
        creator.expects(:run)
        GithubIssueCreator.expects(:new).returns(creator)

        ::Loaders::ScData::AllJob.new.perform

        assert_equal "warning", notification.severity
      end

      test "#perform marks import as failed on error" do
        ::ScData::Loader::BaseLoader.stubs(:all).raises(StandardError, "sc data error")

        error = assert_raises(StandardError) { ::Loaders::ScData::AllJob.new.perform }
        assert_equal "sc data error", error.message

        import = Imports::ScData::AllImport.last
        assert_equal "failed", import.aasm_state
        assert_equal "sc data error", import.info
      end
    end
  end
end
