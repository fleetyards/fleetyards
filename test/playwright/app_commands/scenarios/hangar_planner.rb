# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating hangar_planner scenario test data..."

Flipper.add(:hangar_planner) unless Flipper.exist?(:hangar_planner)
Flipper.enable(:hangar_planner)

user = FactoryBot.create(:user, username: "planner", password: "password")
cutlass = FactoryBot.create(:model, name: "Cutlass Black", pledge_price: 110, on_sale: true)
carrack = FactoryBot.create(:model, name: "Carrack", pledge_price: 600, on_sale: true)
aurora = FactoryBot.create(:model, name: "Aurora MR", pledge_price: 30, on_sale: true)

FactoryBot.create(:vehicle, user:, model: cutlass)
FactoryBot.create(:vehicle, user:, model: aurora, rsi_pledge_id: "planner-aurora", rsi_pledge_melt_value: 30,
  rsi_pledge_meltable: true, rsi_pledge_item_count: 1)
FactoryBot.create(:hangar_pledge_item, user:, kind: "ccu", name: "Upgrade - Cutlass Black To Carrack")

plan = user.hangar_plans.create!(name: "Endgame")
plan.slots.create!(label: "Explorer").candidates.create!(model: carrack)

Rails.logger.info "E2E: Created hangar_planner scenario test data"
