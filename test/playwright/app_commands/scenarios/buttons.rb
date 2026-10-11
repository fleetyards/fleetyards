# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating buttons scenario test data..."

# The Btn specs read the paginator, which only renders its arrows - and only
# disables one of them - when the list spans more than one page. Per-page is a
# persisted client setting rather than a query param, so the count has to come
# from the data.
manufacturer = Manufacturer.find_or_create_by!(name: "Aegis Dynamics") { |m| m.code = "AEGS" }

FactoryBot.create_list(:model, Model.default_per_page + 1, manufacturer: manufacturer)

Rails.logger.info "E2E: Created buttons scenario test data"
