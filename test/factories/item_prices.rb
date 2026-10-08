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
