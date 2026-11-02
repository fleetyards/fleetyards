# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating raffles_placeholder_email scenario test data..."

FactoryBot.create(:user, username: "noemail", password: "password", email: "1001@users.noreply.fleetyards.net")

FactoryBot.create(:raffle, title: "Open Raffle")

Rails.logger.info "E2E: Created raffles_placeholder_email scenario test data"
