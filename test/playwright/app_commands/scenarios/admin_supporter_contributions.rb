# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_supporter_contributions scenario test data..."

AdminUser.find_or_create_by!(username: "admin_supporters") do |u|
  u.email = "admin_supporters@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

FundingGoal.create!(
  title: "Server costs",
  amount_cents: 9_000,
  currency: "EUR",
  effective_from: 2.years.ago.to_date
)

# A spread that exercises every branch of the monthly bucketing: a recurring
# contribution still running, one that churned mid-window, and a one-off.
SupporterContribution.create!(
  name: "Long running patron",
  amount_cents: 2_500,
  currency: "EUR",
  recurring: true,
  started_at: 6.months.ago.to_date
)

SupporterContribution.create!(
  name: "Former patron",
  amount_cents: 1_000,
  currency: "EUR",
  recurring: true,
  started_at: 10.months.ago.to_date,
  ended_at: 3.months.ago.to_date
)

SupporterContribution.create!(
  name: "One off supporter",
  amount_cents: 5_000,
  currency: "EUR",
  recurring: false,
  started_at: Date.current
)

Rails.logger.info "E2E: Created admin_supporter_contributions scenario test data"
