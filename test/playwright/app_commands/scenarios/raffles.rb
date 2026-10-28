# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating raffles scenario test data..."

Flipper.add(:raffles) unless Flipper.exist?(:raffles)
Flipper.enable(:raffles)

FactoryBot.create(:user, username: "entrant", password: "password")

FactoryBot.create(:raffle, title: "Open Raffle")

Rails.logger.info "E2E: Created raffles scenario test data"
