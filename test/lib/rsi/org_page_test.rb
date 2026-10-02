# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class OrgPageTest < ActiveSupport::TestCase
    def org_page_body(intro: "", manifesto: "")
      format(Rails.root.join("test/fixtures/rsi/org_page.html").read, intro:, manifesto:)
    end

    test "a page carries the org's symbol and every section's text" do
      stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST")
        .to_return(status: 200, body: org_page_body(manifesto: "FLEETYARDS-ABC"))

      page = OrgPage.fetch("TEST")

      assert_equal :ok, page.status
      assert_equal "TEST", page.symbol
      assert_includes page.text, "FLEETYARDS-ABC"
    end

    test "a page carries the org's activities and commitment" do
      stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST")
        .to_return(status: 200, body: org_page_body.sub('alt="Social"', 'alt="Bounty Hunting"'))

      page = OrgPage.fetch("TEST")

      assert_equal "bounty_hunting", page.primary_activity
      assert_equal "security", page.secondary_activity
      assert_equal "casual", page.commitment
    end

    test "an activity RSI added since is left blank rather than guessed" do
      stub_request(:get, "https://robertsspaceindustries.com/en/orgs/TEST")
        .to_return(status: 200, body: org_page_body.sub('alt="Social"', 'alt="Racing"'))

      page = OrgPage.fetch("TEST")

      assert_nil page.primary_activity
      assert_equal "security", page.secondary_activity
    end

    test "an unknown org is not found" do
      stub_request(:get, "https://robertsspaceindustries.com/en/orgs/NOPE").to_return(status: 404)

      assert_equal :not_found, OrgPage.fetch("NOPE").status
    end

    test "a block is logged once for every org page" do
      stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/en/orgs/}).to_return(status: 403)

      assert_difference -> { RsiRequestLog.count }, 1 do
        assert_equal :blocked, OrgPage.fetch("ONE").status
        assert_equal :blocked, OrgPage.fetch("TWO").status
      end
    end
  end
end
