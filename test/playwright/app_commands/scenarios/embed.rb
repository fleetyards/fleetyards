# Recreates the seed data needed by embed test pages
require "factory_bot_rails"

Rails.logger.info "E2E: Creating embed scenario test data..."

# Models needed by embed widgets
misc = Manufacturer.find_or_create_by!(name: "MISC")
misc.update!(code: "MISC") if misc.code.blank?
origin = Manufacturer.find_or_create_by!(name: "Origin")
origin.update!(code: "ORIG") if origin.code.blank?

freelancer = Model.find_or_create_by!(name: "Freelancer") do |m|
  m.hidden = false
  m.manufacturer = misc
end
freelancer.update!(manufacturer: misc) if freelancer.manufacturer != misc

m300i = Model.find_or_create_by!(name: "300i") do |m|
  m.hidden = false
  m.manufacturer = origin
end
m300i.update!(manufacturer: origin) if m300i.manufacturer != origin

m600i = Model.find_or_create_by!(name: "600i Explorer") do |m|
  m.hidden = false
  m.manufacturer = origin
end
m600i.update!(manufacturer: origin) if m600i.manufacturer != origin

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
