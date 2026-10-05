# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating squadrons scenario test data..."

Flipper.add(:fleet_squadrons) unless Flipper.exist?(:fleet_squadrons)
Flipper.enable(:fleet_squadrons)

admin = FactoryBot.create(:user, username: "squadrons", password: "password")
fleet = FactoryBot.create(:fleet, :with_squadrons, fid: "SQUADS", name: "Squadron Fleet", admins: [admin])

# Taken, so creating another squadron under this name is the server's 400.
FactoryBot.create(:fleet_squadron, fleet:, name: "Alpha Wing")

Rails.logger.info "E2E: Created squadrons scenario test data"
