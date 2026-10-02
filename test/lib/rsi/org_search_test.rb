# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Rsi
  class OrgSearchTest < ActiveSupport::TestCase
    URL = "https://robertsspaceindustries.com/api/orgs/getOrgs"

    def search_body
      Rails.root.join("test/fixtures/rsi/org_search.json").read
    end

    test "the row whose symbol is the SID answers, not the first loose match" do
      stub_request(:post, URL).with(body: hash_including("search" => "TEST")).to_return(status: 200, body: search_body)

      result = OrgSearch.fetch("TEST")

      assert_equal :ok, result.status
      assert_equal "en", result.language
      assert result.recruiting
      assert result.roleplay
      assert_equal "casual", result.commitment
    end

    def empty_page
      {success: 1, code: "OK", data: {totalrows: 0, html: ""}}.to_json
    end

    test "a SID with no exact row is not found" do
      stub_request(:post, URL).with(body: hash_including("page" => 1)).to_return(status: 200, body: search_body)
      stub_request(:post, URL).with(body: hash_including("page" => 2)).to_return(status: 200, body: empty_page)

      assert_equal :not_found, OrgSearch.fetch("TES").status
    end

    # The fixture with every TEST symbol renamed, so the exact row is not on it.
    def page_without_exact_row
      payload = JSON.parse(search_body)
      payload["data"]["html"] = payload["data"]["html"].gsub(">TEST<", ">TESTY<")
      payload.to_json
    end

    test "the exact row is looked for on the pages after the first" do
      stub_request(:post, URL).with(body: hash_including("page" => 1)).to_return(status: 200, body: page_without_exact_row)
      stub_request(:post, URL).with(body: hash_including("page" => 2)).to_return(status: 200, body: search_body)

      assert_equal "en", OrgSearch.fetch("TEST").language
      assert_requested :post, URL, times: 2
    end

    test "the search gives up after a few pages" do
      stub_request(:post, URL).to_return(status: 200, body: search_body)

      assert_equal :not_found, OrgSearch.fetch("NOPE").status
      assert_requested :post, URL, times: OrgSearch::MAX_PAGES
    end

    test "a language RSI added since is left blank rather than guessed" do
      stub_request(:post, URL).to_return(status: 200, body: search_body.gsub("English", "Klingon"))

      result = OrgSearch.fetch("TEST")

      assert_nil result.language
      assert result.recruiting
    end

    test "a response that is not the search's JSON fails" do
      stub_request(:post, URL).to_return(status: 200, body: "<html>maintenance</html>")

      assert_equal :failed, OrgSearch.fetch("TEST").status
    end

    test "a block is logged" do
      stub_request(:post, URL).to_return(status: 403)

      assert_difference -> { RsiRequestLog.count }, 1 do
        assert_equal :blocked, OrgSearch.fetch("TEST").status
      end
    end
  end
end
