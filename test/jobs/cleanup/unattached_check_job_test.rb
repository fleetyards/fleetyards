# frozen_string_literal: true

require "test_helper"

module Cleanup
  class UnattachedCheckJobTest < ActiveJob::TestCase
    test "#perform purges unattached blobs older than 2 days" do
      blob = mock("blob")
      blob.expects(:purge_later)

      scope = mock("scope")
      scope.stubs(:where).returns(scope)
      scope.stubs(:find_each).yields(blob)

      ActiveStorage::Blob.stubs(:unattached).returns(scope)

      ::Cleanup::UnattachedCheckJob.new.perform
    end
  end
end
