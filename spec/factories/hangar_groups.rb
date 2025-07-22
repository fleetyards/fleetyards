# == Schema Information
#
# Table name: hangar_groups
#
#  id         :uuid             not null, primary key
#  color      :string
#  name       :string
#  public     :boolean          default(FALSE)
#  slug       :string
#  sort       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_hangar_groups_on_user_id_and_name  (user_id,name) UNIQUE
#
FactoryBot.define do
  factory :hangar_group do
    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    color { Faker::Color.hex_color }
    public { false }

    association :user

    trait :with_vehicles do
      after(:create) do |hangar_group|
        create_list(:vehicle, 3, hangar_group: hangar_group)
      end
    end

    trait :public do
      public { true }
    end
  end
end
