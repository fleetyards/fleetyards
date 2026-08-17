# frozen_string_literal: true

class SeedInitialFundingGoals < ActiveRecord::Migration[8.1]
  GOALS = [
    {title: "Servers", amount_cents: 6_000, effective_from: Date.new(2026, 6, 17)},
    {title: "Mail", amount_cents: 1_000, effective_from: Date.new(2026, 6, 20)},
    {title: "Domains", amount_cents: 1_000, effective_from: Date.new(2026, 6, 20)},
    {title: "CDN", amount_cents: 1_000, effective_from: Date.new(2026, 6, 20)},
    {title: "Cloud Storage", amount_cents: 1_000, effective_from: Date.new(2026, 6, 20)}
  ].freeze

  def up
    GOALS.each do |attrs|
      FundingGoal.find_or_create_by!(title: attrs[:title]) do |goal|
        goal.amount_cents = attrs[:amount_cents]
        goal.currency = "EUR"
        goal.effective_from = attrs[:effective_from]
      end
    end
  end

  def down
    FundingGoal.where(title: GOALS.map { |g| g[:title] }).destroy_all
  end
end
