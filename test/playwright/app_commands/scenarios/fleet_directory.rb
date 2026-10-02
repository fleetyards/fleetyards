# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating fleet_directory scenario test data..."

Flipper.add(:fleet_directory) unless Flipper.exist?(:fleet_directory)
Flipper.enable(:fleet_directory)

directory_fleet = lambda do |name:, fid:, sid:, **profile|
  creator = FactoryBot.create(:user)
  fleet = FactoryBot.create(:fleet, name:, fid:, rsi_sid: sid, created_by: creator.id,
    members: [FactoryBot.create(:user)])
  fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: sid, rsi_verification_status: :verified, **profile) # rubocop:disable Rails/SkipsModelValidations
end

directory_fleet.call(name: "Night Pirates", fid: "NIGHT", sid: "PIRATES",
  primary_activity: "piracy", secondary_activity: "smuggling", language: "en", recruiting: true)
directory_fleet.call(name: "Deep Diggers", fid: "DIGGERS", sid: "DIGDEEP",
  primary_activity: "resources", language: "de", recruiting: false)

Rails.logger.info "E2E: Created fleet_directory scenario test data"
