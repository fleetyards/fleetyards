# == Schema Information
#
# Table name: item_prices
#
#  id                :uuid             not null, primary key
#  item_type         :string           not null
#  location          :string
#  location_url      :string
#  price             :decimal(15, 2)
#  price_type        :integer
#  scu               :integer
#  source_updated_at :datetime
#  time_range        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  item_id           :uuid             not null
#  terminal_id       :uuid
#
# Indexes
#
#  index_item_prices_on_item         (item_type,item_id)
#  index_item_prices_on_terminal_id  (terminal_id)
#
# Foreign Keys
#
#  fk_rails_...  (terminal_id => terminals.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :item_price do
    price_type { ItemPrice.price_types.keys.sample }
    price { Faker::Number.decimal(l_digits: 2) }
    location { Faker::Address.city }
    location_url { Faker::Internet.url }
    time_range { ItemPrice.time_ranges.keys.sample }
    item { create(:model) }
  end
end
