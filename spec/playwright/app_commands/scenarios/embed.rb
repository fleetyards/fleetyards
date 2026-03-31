# Recreates the seed data needed by embed test pages
require "factory_bot_rails"

Rails.logger.info "E2E: Creating embed scenario test data..."

# Models needed by embed widgets
freelancer = Model.find_or_create_by!(name: "Freelancer") do |m|
  m.hidden = false
  m.manufacturer = Manufacturer.find_or_create_by!(name: "MISC")
end

Model.find_or_create_by!(name: "300i") do |m|
  m.hidden = false
  m.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
end

Model.find_or_create_by!(name: "600i Explorer") do |m|
  m.hidden = false
  m.manufacturer = Manufacturer.find_or_create_by!(name: "Origin")
end

# TestUser with Freelancer vehicles (for embed-v2-username-test)
test_user = User.find_or_initialize_by(username: "TestUser")
test_user.skip_confirmation!
test_user.update!(
  password: "TestPassword",
  password_confirmation: "TestPassword",
  email: "test@fleetyards.net"
)

2.times do |index|
  Vehicle.find_or_create_by!(
    user_id: test_user.id,
    model_id: freelancer.id,
    name: "freelancer-#{index}",
    wanted: false,
    public: true
  )
end

# TestFleet (for embed-v2-fleet-test)
fleet = Fleet.find_or_create_by!(
  name: "TestFleet",
  fid: "TESTFLEET",
  created_by: test_user.id,
  public_fleet: true
)

fleet.fleet_memberships.each do |membership|
  membership.setup_fleet_vehicles
end

Rails.logger.info "E2E: Created embed scenario test data"
