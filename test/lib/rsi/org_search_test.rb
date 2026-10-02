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

    test "a SID with no exact row is not found" do
      stub_request(:post, URL).to_return(status: 200, body: search_body)

      assert_equal :not_found, OrgSearch.fetch("TES").status
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
