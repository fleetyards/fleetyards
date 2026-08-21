# frozen_string_literal: true

json.currency @monthly_stats.currency

json.items @monthly_stats.entries do |month|
  json.label I18n.l(month.starts_on, format: :month_year_short)
  json.tooltip I18n.l(month.starts_on, format: :month_year)
  json.amount_cents month.amount_cents
  json.goal_amount_cents month.goal_amount_cents
  json.count month.count
end
