# == Schema Information
#
# Table name: model_module_packages
#
#  id                 :uuid             not null, primary key
#  active             :boolean          default(TRUE)
#  angled_view        :string
#  angled_view_height :integer
#  angled_view_width  :integer
#  description        :text
#  hidden             :boolean          default(TRUE)
#  name               :string
#  pledge_price       :decimal(15, 2)
#  side_view          :string
#  side_view_height   :integer
#  side_view_width    :integer
#  slug               :string
#  store_image        :string
#  store_image_height :integer
#  store_image_width  :integer
#  top_view           :string
#  top_view_height    :integer
#  top_view_width     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  model_id           :uuid
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
