# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating notifications scenario test data..."

user = User.find_or_create_by!(username: "notifications") do |u|
  u.email = "notifications@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.confirmed_at = Time.current
end

# A real, still-open invite behind the invite example. The reading pane decides
# its actions from the membership's current state, so without this the fixture
# would only ever show the link.
fleet = FactoryBot.create(:fleet, name: "Test Fleet", admins: [FactoryBot.create(:user)])
invite = FactoryBot.create(
  :fleet_membership,
  fleet: fleet,
  user: user,
  fleet_role: fleet.fleet_roles.ranked.last,
  aasm_state: :invited
)

NotificationExamples.create_for(user, records: {fleet_invite: invite})

Rails.logger.info "E2E: Created notifications scenario test data"
