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
class ExchangeRate < ApplicationRecord
  validates :from_currency, presence: true
  validates :to_currency, presence: true,
    uniqueness: {scope: :from_currency, case_sensitive: false}
  validates :rate, presence: true, numericality: {greater_than: 0}
  validates :fetched_at, presence: true
end
