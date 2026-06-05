# frozen_string_literal: true

require "test_helper"

module ScData
  class CheckJobTest < ActiveJob::TestCase
    test "#perform enqueues AllJob when version is new" do
      Rails.configuration.stubs(:sc_data).returns({version: "3.24.0"})
      Imports::ScData::AllImport.stubs(:finished).returns(stub(exists?: false))

      Loaders::ScData::AllJob.expects(:perform_async).with("3.24.0")

      ::ScData::CheckJob.new.perform
    end

    test "#perform does not enqueue AllJob when version is blank" do
      Rails.configuration.stubs(:sc_data).returns({version: nil})

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end

    test "#perform does not enqueue AllJob when import already finished for version" do
      Rails.configuration.stubs(:sc_data).returns({version: "3.24.0"})
      Imports::ScData::AllImport.stubs(:finished).returns(stub(exists?: true))

      Loaders::ScData::AllJob.expects(:perform_async).never

      ::ScData::CheckJob.new.perform
    end
  end
end
