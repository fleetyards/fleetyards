# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Uex
  class ClientTest < ActiveSupport::TestCase
    BASE = "https://uex.test/2.0"

    setup do
      @client = Uex::Client.new(base_url: BASE)
    end

    test "fetches and unwraps each bulk endpoint" do
      {
        vehicles: "vehicles",
        vehicle_purchase_prices: "vehicles_purchases_prices_all",
        vehicle_rental_prices: "vehicles_rentals_prices_all",
        terminals: "terminals"
      }.each do |method, path|
        stub_request(:get, "#{BASE}/#{path}/")
          .to_return(body: {status: "ok", data: [{"id" => 1}]}.to_json)

        assert_equal [{"id" => 1}], @client.public_send(method), "expected #{method} to unwrap data"
      end
    end

    test "sends a User-Agent, which UEX rejects requests without" do
      stub_request(:get, "#{BASE}/vehicles/")
        .with(headers: {"User-Agent" => /Fleetyards/})
        .to_return(body: {status: "ok", data: []}.to_json)

      assert_equal [], @client.vehicles
    end

    test "raises on a non-success response" do
      stub_request(:get, "#{BASE}/terminals/").to_return(status: 403, body: "Forbidden")

      error = assert_raises(Uex::Error) { @client.terminals }
      assert_match "403", error.message
    end

    test "raises when the payload status is not ok" do
      stub_request(:get, "#{BASE}/terminals/")
        .to_return(body: {status: "error", data: nil}.to_json)

      error = assert_raises(Uex::Error) { @client.terminals }
      assert_match "error", error.message
    end

    test "raises when data is null rather than handing back an empty snapshot" do
      stub_request(:get, "#{BASE}/terminals/")
        .to_return(body: {status: "ok", data: nil}.to_json)

      assert_raises(Uex::Error) { @client.terminals }
    end

    test "raises on invalid JSON" do
      stub_request(:get, "#{BASE}/terminals/").to_return(body: "<html>nope</html>")

      assert_raises(Uex::Error) { @client.terminals }
    end
  end
end
