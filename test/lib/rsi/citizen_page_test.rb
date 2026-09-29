# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class CitizenPageTest < ActiveSupport::TestCase
    def citizen_page_body(handle: "TestPilot", bio: "", org_name: "Test Squadron")
      format(Rails.root.join("test/fixtures/rsi/citizen_page.html").read, handle:, bio:, org_name:)
    end

    test "a page carries the citizen's handle and bio" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/testpilot")
        .to_return(status: 200, body: citizen_page_body(bio: "FLEETYARDS-ABC"))

      page = CitizenPage.fetch("testpilot")

      assert_equal :ok, page.status
      assert_equal "TestPilot", page.handle
      assert_includes page.bio, "FLEETYARDS-ABC"
    end

    test "the main org's name is not part of the bio" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/TestPilot")
        .to_return(status: 200, body: citizen_page_body(org_name: "FLEETYARDS-ABC"))

      refute_includes CitizenPage.fetch("TestPilot").bio, "FLEETYARDS-ABC"
    end

    test "an unknown citizen is not found" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/nope").to_return(status: 404)

      assert_equal :not_found, CitizenPage.fetch("nope").status
    end

    test "a block is logged once for every citizen page" do
      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/en/citizens/}).to_return(status: 403)

      assert_difference -> { RsiRequestLog.count }, 1 do
        assert_equal :failed, CitizenPage.fetch("one").status
        assert_equal :failed, CitizenPage.fetch("two").status
      end
    end
  end
end
