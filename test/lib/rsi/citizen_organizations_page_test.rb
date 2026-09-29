# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class CitizenOrganizationsPageTest < ActiveSupport::TestCase
    def page_body(main: "MAIN", affiliation: "WING", redacted: "SECRET")
      format(Rails.root.join("test/fixtures/rsi/citizen_organizations_page.html").read, main:, affiliation:, redacted:)
    end

    test "a page lists the SIDs of the visible main org and affiliations" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/testpilot/organizations")
        .to_return(status: 200, body: page_body)

      page = CitizenOrganizationsPage.fetch("testpilot")

      assert_equal :ok, page.status
      assert_equal %w[MAIN WING], page.sids
    end

    test "a redacted org does not count" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/testpilot/organizations")
        .to_return(status: 200, body: page_body)

      refute_includes CitizenOrganizationsPage.fetch("testpilot").sids, "SECRET"
    end

    test "an unknown citizen is not found" do
      stub_request(:get, "https://robertsspaceindustries.com/en/citizens/nope/organizations").to_return(status: 404)

      assert_equal :not_found, CitizenOrganizationsPage.fetch("nope").status
    end

    test "a refusal is a block, logged once with the citizen pages" do
      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/en/citizens/}).to_return(status: 403)

      assert_difference -> { RsiRequestLog.count }, 1 do
        assert_equal :blocked, CitizenOrganizationsPage.fetch("one").status
        assert_equal :blocked, CitizenOrganizationsPage.fetch("two").status
        assert_equal :failed, CitizenPage.fetch("three").status
      end
    end
  end
end
