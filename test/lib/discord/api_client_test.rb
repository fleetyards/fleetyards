# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Discord
  class ApiClientTest < ActiveSupport::TestCase
    MEMBER_URL = "https://discord.com/api/v10/guilds/100000000000000001/members/200000000000000001"

    test "a client without a timeout retries a rate limit" do
      stub_request(:get, MEMBER_URL)
        .to_return({status: 429, headers: {"Retry-After" => "0"}}, {status: 200, body: {roles: []}.to_json})

      assert_equal({"roles" => []}, ApiClient.new(token: "token").get_guild_member("100000000000000001", "200000000000000001"))
    end

    test "a client with a timeout makes a single attempt" do
      stub_request(:get, MEMBER_URL).to_return(status: 429, headers: {"Retry-After" => "30"})

      error = assert_raises(ApiClient::Error) do
        ApiClient.new(token: "token", timeout: 3).get_guild_member("100000000000000001", "200000000000000001")
      end

      assert_equal 429, error.status
      assert_requested :get, MEMBER_URL, times: 1
    end
  end
end
