# frozen_string_literal: true

class ExchangeRate < ApplicationRecord
  validates :from_currency, presence: true
  validates :to_currency, presence: true,
    uniqueness: {scope: :from_currency, case_sensitive: false}
  validates :rate, presence: true, numericality: {greater_than: 0}
  validates :fetched_at, presence: true
end
