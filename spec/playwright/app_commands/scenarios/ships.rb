# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating ships scenario test data..."

model = FactoryBot.create(:model, :with_legacy_images, name: "Ironclad")
FactoryBot.create_list(:image, 10, gallery: model)

FactoryBot.create(:model, :with_legacy_images, name: "Corsair")

Model.reindex

Rails.logger.info "E2E: Created ships scenario test data"
