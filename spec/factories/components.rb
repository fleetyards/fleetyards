# == Schema Information
#
# Table name: components
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string(255)
#  power_connection      :string
#  sc_identifier         :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  store_image           :string
#  store_image_height    :integer
#  store_image_width     :integer
#  tracking_signal       :integer
#  type_data             :string
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#
FactoryBot.define do
  factory :component do
    name { Faker::Name.name }
    component_class { "RSIModular" }
  end
end
