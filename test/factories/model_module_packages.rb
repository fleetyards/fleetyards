# == Schema Information
#
# Table name: model_module_packages
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(TRUE)
#  description  :text
#  hidden       :boolean          default(TRUE)
#  name         :string
#  pledge_price :decimal(15, 2)
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid
#
FactoryBot.define do
  factory :model_module_package do
    name { Faker::Name.name }
    model_modules { create_list(:model_module, 2) }
    model
    active { true }
    hidden { false }
  end
end
