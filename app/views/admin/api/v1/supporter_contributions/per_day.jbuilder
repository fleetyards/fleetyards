# frozen_string_literal: true

json.currency @daily_stats.currency
json.goal_amount_cents @daily_stats.goal_amount_cents

json.items @daily_stats.entries do |month|
  json.label I18n.l(month.starts_on, format: :month_year)
  json.current month.current
  json.days month.days
end
