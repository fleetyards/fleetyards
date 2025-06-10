# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating images scenario test data..."

FactoryBot.create_list(:image, 10, gallery: model)

Rails.logger.info "E2E: Created images scenario test data"
