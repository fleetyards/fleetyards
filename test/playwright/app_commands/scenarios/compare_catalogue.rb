require "factory_bot_rails"

Rails.logger.info "E2E: Creating compare catalogue scenario test data..."

[
  ["Palisade", "palisade", 2_000],
  ["Rampart", "rampart", 3_500]
].each do |name, slug, health|
  component = FactoryBot.create(:component, name:, category: "shieldgenerator", type_data: {"maxHealth" => health, "maxRegen" => 100})
  component.update_columns(slug:)
end

FactoryBot.create(:component, name: "Atlas", category: "quantumdrive").update_columns(slug: "atlas")
