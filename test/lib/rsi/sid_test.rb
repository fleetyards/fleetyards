# frozen_string_literal: true

require "test_helper"

module Rsi
  class SidTest < ActiveSupport::TestCase
    {
      "TEST" => "TEST",
      "test" => "TEST",
      "  TEST " => "TEST",
      "https://robertsspaceindustries.com/orgs/TEST" => "TEST",
      "https://robertsspaceindustries.com/en/orgs/TEST" => "TEST",
      "https://robertsspaceindustries.com/orgs/TEST/members" => "TEST",
      "robertsspaceindustries.com/orgs/test" => "TEST",
      "https://www.robertsspaceindustries.com/orgs/TEST?tab=history" => "TEST",
      "[TEST]" => "TEST",
      "TEST/" => "TEST"
    }.each do |input, sid|
      test "#{input.inspect} normalises to #{sid}" do
        assert_equal sid, Sid.normalize(input)
        assert Sid.valid?(Sid.normalize(input))
      end
    end

    [
      "@handle",
      "#1437915",
      "https://robertsspaceindustries.com/citizens/handle",
      "Few Seconds Hero",
      "Some-Handle",
      "ELEVENCHARS",
      "person@example.com",
      "/"
    ].each do |input|
      test "#{input.inspect} is not a SID" do
        assert_not Sid.valid?(Sid.normalize(input))
      end
    end

    test "blank becomes nil" do
      assert_nil Sid.normalize("  ")
      assert_nil Sid.normalize(nil)
    end
  end
end
