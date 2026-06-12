# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating hangar scenario test data..."

# Hangar tests need a 300i model for add-to-hangar workflow
unless Model.exists?(name: "300i")
  origin = Manufacturer.find_or_create_by!(name: "Origin") { |m| m.code = "ORIG" }
  FactoryBot.create(:model, :with_legacy_images, name: "300i", production_status: "flight-ready",
    manufacturer: origin)
end

Rails.logger.info "E2E: Created hangar scenario test data"
