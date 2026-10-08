FactoryBot.define do
  factory :model_snub_craft do
    model
    snub_craft { create(:model) }
  end
end
