# frozen_string_literal: true

class ExchangeRateFetcher
  ENDPOINT = "https://api.frankfurter.dev/v1/latest"
  CACHE_KEY = "exchange_rate:%s:%s"
  CACHE_TTL = 12.hours

  class FetchError < StandardError; end

  def self.fetch(from:, to:)
    key = format(CACHE_KEY, from, to)
    cached = Rails.cache.read(key)
    return cached if cached

    rate = remote_rate(from:, to:)
    # Only cache fresh remote rates. The DB snapshot fallback is deliberately
    # left uncached so the next call retries the provider rather than serving a
    # stale rate for the full TTL.
    return cached_rate(from:, to:) if rate.blank?

    Rails.cache.write(key, rate, expires_in: CACHE_TTL)
    rate
  end

  def self.convert_cents(cents, from:, to:)
    return cents if from.to_s == to.to_s

    (cents * fetch(from:, to:)).round
  end

  def self.remote_rate(from:, to:)
    response = Typhoeus.get(ENDPOINT, params: {from: from.to_s, to: to.to_s}, followlocation: true)
    return nil unless response.success?

    rate = JSON.parse(response.body).dig("rates", to.to_s)&.to_d
    return nil if rate.blank?

    ExchangeRate
      .find_or_initialize_by(from_currency: from.to_s, to_currency: to.to_s)
      .update!(rate:, fetched_at: Time.current)
    rate
  rescue JSON::ParserError => e
    Appsignal.report_error(e)
    nil
  end

  def self.cached_rate(from:, to:)
    record = ExchangeRate.find_by(from_currency: from.to_s, to_currency: to.to_s)
    raise FetchError, "no fallback exchange rate for #{from}->#{to}" if record.blank?

    Appsignal.report_error(FetchError.new("Frankfurter unreachable, using #{from}->#{to} rate from #{record.fetched_at.iso8601}"))
    record.rate
  end
end
