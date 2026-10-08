# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Discord
  class InteractionClientTest < ActiveSupport::TestCase
    BASE = "https://discord.com/api/v10/webhooks/app/token"

    setup do
      @client = InteractionClient.new(application_id: "app", token: "token")
    end

    # An answer that repeats a query typed as "@everyone" must not ping the guild.
    test "an edited answer pings no one" do
      request = stub_request(:patch, "#{BASE}/messages/@original")
        .with { |req| JSON.parse(req.body)["allowed_mentions"] == {"parse" => []} }
        .to_return(status: 200)

      @client.edit_original({content: 'No ship found for "@everyone".'})

      assert_requested request
    end

    test "a follow-up pings no one" do
      request = stub_request(:post, BASE)
        .with { |req| JSON.parse(req.body)["allowed_mentions"] == {"parse" => []} }
        .to_return(status: 200)

      @client.create_followup({content: "@everyone"})

      assert_requested request
    end
  end
end
