# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating hangar_inventories scenario test data..."

# The pages and every endpoint behind them are gated on this flag, so without it
# the spec would only ever see a 403 and an empty hangar menu.
Flipper.add(:hangar_inventories) unless Flipper.exist?(:hangar_inventories)
Flipper.enable(:hangar_inventories)

Rails.logger.info "E2E: Created hangar_inventories scenario test data"
