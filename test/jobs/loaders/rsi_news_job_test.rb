# frozen_string_literal: true

require "test_helper"

module Loaders
  class RsiNewsJobTest < ActiveJob::TestCase
    test "#perform runs the news loader" do
      loader = mock("Rsi::NewsLoader")
      loader.expects(:update)
      Rsi::NewsLoader.stubs(:new).returns(loader)

      ::Loaders::RsiNewsJob.new.perform
    end
  end
end
