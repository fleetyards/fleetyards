# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating ships scenario test data..."

model = Model.find_or_initialize_by(name: "Ironclad")
if model.new_record?
  model = FactoryBot.create(:model, :with_legacy_images, name: "Ironclad")
end
FactoryBot.create_list(:image, 10, gallery: model) if model.images.count < 10

unless Model.exists?(name: "Corsair")
  FactoryBot.create(:model, :with_legacy_images, name: "Corsair")
end

Model.reindex

Rails.logger.info "E2E: Created ships scenario test data"
