# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating ships scenario test data..."

aegs = Manufacturer.find_or_create_by!(name: "Aegis Dynamics") { |m| m.code = "AEGS" }
drak = Manufacturer.find_or_create_by!(name: "Drake Interplanetary") { |m| m.code = "DRAK" }

model = Model.find_or_initialize_by(name: "Ironclad")
if model.new_record?
  model = FactoryBot.create(:model, :with_legacy_images, name: "Ironclad", manufacturer: aegs)
end
FactoryBot.create_list(:image, 10, gallery: model) if model.images.count < 10

unless Model.exists?(name: "Corsair")
  FactoryBot.create(:model, :with_legacy_images, name: "Corsair", manufacturer: drak)
end

Rails.logger.info "E2E: Created ships scenario test data"
