# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_supporter_contribution_links scenario test data..."

AdminUser.find_or_create_by!(username: "admin_supporters") do |u|
  u.email = "admin_supporters@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

# One row per linking rule, plus an unlinked one -- its own scenario rather than
# an addition to admin_supporter_contributions, whose totals are asserted to the
# cent and would move under any extra contribution.
keyed = FactoryBot.create(:user, username: "token_donor")

SupporterContribution.create!(
  name: "Token donor",
  amount_cents: 1_500,
  currency: "EUR",
  started_at: Date.current,
  note: "keep it up! #{keyed.ensure_claim_key!}"
).then { |contribution| Supporters::Linker.call(contribution) }

FactoryBot.create(:user, username: "mail_donor", email: "mail_donor@test.com")

SupporterContribution.create!(
  name: "Mail donor",
  amount_cents: 2_000,
  currency: "EUR",
  started_at: Date.current,
  payer_email: "mail_donor@test.com"
).then { |contribution| Supporters::Linker.call(contribution) }

SupporterContribution.create!(
  name: "Hand linked donor",
  amount_cents: 3_000,
  currency: "EUR",
  started_at: Date.current,
  user: FactoryBot.create(:user, username: "hand_linked_donor")
)

SupporterContribution.create!(
  name: "Unlinked donor",
  amount_cents: 500,
  currency: "EUR",
  started_at: Date.current
)

Rails.logger.info "E2E: Created admin_supporter_contribution_links scenario test data"
