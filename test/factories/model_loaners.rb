FactoryBot.define do
  factory :model_loaner do
    model
    loaner_model { create(:model) }
  end
end
