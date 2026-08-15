# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating chips scenario test data..."

# Seeded as a *public* hangar so the chip specs need no session: the public page
# renders the same GroupLabels component with the same tri-state filter, and the
# authenticated hangar's login step is what every other spec here spends a minute
# on. The tri-state only proves anything if the groups hold vehicles, so the
# counts and the filtered list both move.
user = User.find_by(username: "chips") || FactoryBot.create(
  :user,
  :public_hangar,
  username: "chips",
  email: "chips@fleetyards.test",
  password: "password",
  password_confirmation: "password"
)

manufacturer = Manufacturer.find_or_create_by!(name: "Aegis Dynamics") { |m| m.code = "AEGS" }

combat = FactoryBot.create(:hangar_group, :public, user: user, name: "Combat", color: "#dc3545")
cargo = FactoryBot.create(:hangar_group, :public, user: user, name: "Cargo", color: "#428bca")

# hangar_groups is a has_many :through :task_forces, so the join is built here
# rather than passed to the vehicle factory.
2.times do
  vehicle = FactoryBot.create(
    :vehicle,
    :public,
    user: user,
    model: FactoryBot.create(:model, manufacturer: manufacturer)
  )
  vehicle.hangar_groups << combat
end

vehicle = FactoryBot.create(
  :vehicle,
  :public,
  user: user,
  model: FactoryBot.create(:model, manufacturer: manufacturer)
)
vehicle.hangar_groups << cargo

Rails.logger.info "E2E: Created chips scenario test data"
