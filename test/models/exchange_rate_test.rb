# frozen_string_literal: true

# == Schema Information
#
# Table name: exchange_rates
#
#  id            :uuid             not null, primary key
#  fetched_at    :datetime         not null
#  from_currency :string           not null
#  rate          :decimal(16, 8)   not null
#  to_currency   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exchange_rates_on_from_currency_and_to_currency  (from_currency,to_currency) UNIQUE
#
require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "requires from/to currency, rate and fetched_at" do
    refute ExchangeRate.new.valid?

    rate = ExchangeRate.new(from_currency: "USD", to_currency: "EUR", rate: 0.92, fetched_at: Time.current)
    assert rate.valid?
  end

  test "rate must be positive" do
    refute build(:exchange_rate, rate: 0).valid?
    refute build(:exchange_rate, rate: -1).valid?
  end

  test "is unique per from/to pair" do
    create(:exchange_rate, from_currency: "USD", to_currency: "EUR")

    duplicate = build(:exchange_rate, from_currency: "USD", to_currency: "EUR")
    refute duplicate.valid?

    other_pair = build(:exchange_rate, from_currency: "USD", to_currency: "GBP")
    assert other_pair.valid?
  end
end
