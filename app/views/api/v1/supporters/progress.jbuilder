# frozen_string_literal: true

goal_total = @goals.sum(&:amount_cents)
goal_currency = @goals.first&.currency || "EUR"

if @goals.any?
  json.goal do
    json.amount_cents goal_total
    json.currency goal_currency
    json.items @goals do |goal|
      json.title goal.title
      json.description goal.description if goal.description.present?
      json.amount_cents goal.amount_cents
      json.currency goal.currency
    end
  end
end

json.monthly_total do
  json.amount_cents @monthly_total
  json.currency goal_currency
end

json.contributions @contributions do |contribution|
  json.display_name contribution.anonymous? ? "Anonymous" : contribution.name
  json.amount_cents contribution.amount_cents
  json.currency contribution.currency
  json.recurring contribution.recurring
end
