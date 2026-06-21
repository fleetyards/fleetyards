# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Patreon
  class ClientTest < ActiveSupport::TestCase
    BASE = "https://www.patreon.com/api/oauth2/v2"
    CAMPAIGN_ID = "camp-1"

    setup do
      @client = Patreon::Client.new(token: "test-token")
    end

    test "#members follows pagination and normalizes each member" do
      page1 = {
        data: [
          {
            id: "m1",
            attributes: {
              full_name: "Alice",
              patron_status: "active_patron",
              currently_entitled_amount_cents: 500,
              pledge_amount_cents: 500,
              pledge_relationship_start: "2026-01-15T00:00:00.000+00:00",
              last_charge_date: "2026-06-01T00:00:00.000+00:00"
            },
            relationships: {user: {data: {id: "u1", type: "user"}}}
          }
        ],
        included: [{id: "u1", type: "user", attributes: {vanity: "alice"}}],
        links: {next: "#{BASE}/campaigns/#{CAMPAIGN_ID}/members?page%5Bcursor%5D=2"}
      }
      page2 = {
        data: [
          {
            id: "m2",
            attributes: {
              full_name: nil,
              patron_status: "former_patron",
              currently_entitled_amount_cents: 0,
              pledge_amount_cents: 1000,
              pledge_relationship_start: "2025-03-01T00:00:00.000+00:00",
              last_charge_date: "2026-05-01T00:00:00.000+00:00"
            },
            relationships: {user: {data: {id: "u2", type: "user"}}}
          }
        ],
        included: [{id: "u2", type: "user", attributes: {vanity: "bob"}}],
        links: {}
      }

      stub_request(:get, "#{BASE}/campaigns/#{CAMPAIGN_ID}/members")
        .with(query: hash_including({}), headers: {"Authorization" => "Bearer test-token"})
        .to_return(status: 200, body: page1.to_json)
      stub_request(:get, "#{BASE}/campaigns/#{CAMPAIGN_ID}/members")
        .with(query: {"page[cursor]" => "2"})
        .to_return(status: 200, body: page2.to_json)

      members = @client.members(CAMPAIGN_ID).to_a

      assert_equal 2, members.size

      alice = members.first
      assert_equal "m1", alice.id
      assert_equal "Alice", alice.name
      assert_equal "active_patron", alice.status
      assert_equal 500, alice.amount_cents
      assert_equal Date.new(2026, 1, 15), alice.pledged_at
      assert_equal Date.new(2026, 6, 1), alice.last_charge_date

      bob = members.last
      assert_equal "bob", bob.name, "falls back to user vanity when full_name is blank"
      assert_equal 1000, bob.amount_cents, "falls back to pledge_amount_cents when entitled is 0"
    end

    test "#members raises Patreon::Error on an expired token" do
      stub_request(:get, "#{BASE}/campaigns/#{CAMPAIGN_ID}/members")
        .with(query: hash_including({}))
        .to_return(status: 401, body: {errors: [{title: "Unauthorized"}]}.to_json)

      assert_raises(Patreon::Error) do
        @client.members(CAMPAIGN_ID).to_a
      end
    end

    test "#members reports truncation when the page cap is hit" do
      endless_page = {
        data: [{
          id: "m",
          attributes: {patron_status: "active_patron", currently_entitled_amount_cents: 100},
          relationships: {}
        }],
        included: [],
        links: {next: "#{BASE}/campaigns/#{CAMPAIGN_ID}/members?page%5Bcursor%5D=loop"}
      }
      stub_request(:get, %r{#{Regexp.escape(BASE)}/campaigns/#{CAMPAIGN_ID}/members}o)
        .to_return(status: 200, body: endless_page.to_json)
      Appsignal.expects(:report_error).once

      members = @client.members(CAMPAIGN_ID).to_a

      assert_equal Patreon::Client::MAX_PAGES, members.size
    end
  end
end
