# == Schema Information
#
# Table name: model_snub_crafts
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid             not null
#  snub_craft_id :uuid             not null
#
FactoryBot.define do
  factory :model_snub_craft do
    model
    snub_craft { create(:model) }
  end
end
