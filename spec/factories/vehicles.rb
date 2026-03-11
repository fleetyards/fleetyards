# == Schema Information
#
# Table name: vehicles
#
#  id                   :uuid             not null, primary key
#  alternative_names    :string
#  bought_via           :integer          default("pledge_store")
#  flagship             :boolean          default(FALSE)
#  hidden               :boolean          default(FALSE)
#  loaner               :boolean          default(FALSE)
#  name                 :string(255)
#  name_visible         :boolean          default(FALSE)
#  notify               :boolean          default(TRUE)
#  public               :boolean          default(FALSE)
#  rsi_pledge_synced_at :datetime
#  sale_notify          :boolean          default(FALSE)
#  serial               :string
#  slug                 :string
#  wanted               :boolean          default(FALSE)
#  created_at           :datetime
#  updated_at           :datetime
#  model_id             :uuid
#  model_paint_id       :uuid
#  module_package_id    :uuid
#  rsi_pledge_id        :string
#  user_id              :uuid
#  vehicle_id           :uuid
#
# Indexes
#
#  index_vehicles_on_hidden_and_loaner   (hidden,loaner)
#  index_vehicles_on_model_id_and_id     (model_id,id)
#  index_vehicles_on_serial_and_user_id  (serial,user_id) UNIQUE
#  index_vehicles_on_user_id             (user_id)
#
FactoryBot.define do
  factory :vehicle do
    model
    user

    wanted { false }
    loaner { false }

    trait :with_name do
      name { Faker::Name.name }
      name_visible { true }
    end

    trait :wanted do
      wanted { true }
    end

    trait :loaner do
      loaner { true }
    end

    trait :flagship do
      flagship { true }
    end

    trait :hidden do
      hidden { true }
    end

    trait :public do
      public { true }
    end

    trait :bought_ingame do
      bought_via { :ingame }
    end

    trait :with_serial do
      serial { SecureRandom.hex(8) }
    end

    trait :with_paint do
      model_paint { association :model_paint, model: model }
    end
  end
end
