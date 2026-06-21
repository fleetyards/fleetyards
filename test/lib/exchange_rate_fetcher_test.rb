# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class ExchangeRateFetcherTest < ActiveSupport::TestCase
  ENDPOINT = %r{\Ahttps://api\.frankfurter\.dev/v1/latest}

  test "fetches a remote rate and upserts the snapshot row" do
    stub_request(:get, ENDPOINT)
      .with(query: {from: "USD", to: "EUR"})
      .to_return(status: 200, body: {amount: 1.0, base: "USD", rates: {EUR: 0.9}}.to_json)

    rate = ExchangeRateFetcher.fetch(from: :USD, to: :EUR)

    assert_equal BigDecimal("0.9"), rate
    snapshot = ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR")
    assert_equal BigDecimal("0.9"), snapshot.rate
    assert snapshot.fetched_at.present?
  end

  test "updates the existing snapshot row in place on re-fetch" do
    create(:exchange_rate, from_currency: "USD", to_currency: "EUR", rate: 0.8)
    stub_request(:get, ENDPOINT)
      .with(query: {from: "USD", to: "EUR"})
      .to_return(status: 200, body: {rates: {EUR: 0.95}}.to_json)

    ExchangeRateFetcher.fetch(from: :USD, to: :EUR)

    assert_equal 1, ExchangeRate.where(from_currency: "USD", to_currency: "EUR").count
    assert_equal BigDecimal("0.95"), ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR").rate
  end

  test "falls back to the cached snapshot when the provider errors" do
    create(:exchange_rate, from_currency: "USD", to_currency: "EUR", rate: 0.85)
    stub_request(:get, ENDPOINT).to_return(status: 503)
    Appsignal.expects(:report_error).once

    rate = ExchangeRateFetcher.fetch(from: :USD, to: :EUR)

    assert_equal BigDecimal("0.85"), rate
  end

  test "raises when the provider errors and no snapshot exists" do
    stub_request(:get, ENDPOINT).to_return(status: 503)

    assert_raises(ExchangeRateFetcher::FetchError) do
      ExchangeRateFetcher.fetch(from: :USD, to: :EUR)
    end
  end

  test "convert_cents returns input unchanged for same currency" do
    assert_equal 500, ExchangeRateFetcher.convert_cents(500, from: :EUR, to: :EUR)
  end

  test "convert_cents rounds the converted amount" do
    stub_request(:get, ENDPOINT)
      .with(query: {from: "USD", to: "EUR"})
      .to_return(status: 200, body: {rates: {EUR: 0.9}}.to_json)

    assert_equal 449, ExchangeRateFetcher.convert_cents(499, from: :USD, to: :EUR)
  end
end
