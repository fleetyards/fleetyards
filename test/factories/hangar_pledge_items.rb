# == Schema Information
#
# Table name: hangar_pledge_items
#
#  id                :uuid             not null, primary key
#  image_url         :string
#  kind              :string           not null
#  meltable          :boolean          default(FALSE), not null
#  name              :string           not null
#  pledge_created_on :date
#  pledge_item_count :integer
#  pledge_name       :string
#  pledge_value      :decimal(15, 2)
#  quantity          :integer          default(1), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  rsi_pledge_id     :string           not null
#  user_id           :uuid             not null
#
# Indexes
#
#  index_hangar_pledge_items_on_user_kind_pledge_name  (user_id,kind,rsi_pledge_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :hangar_pledge_item do
    kind { "paint" }
    sequence(:rsi_pledge_id) { |n| (10_000_000 + n).to_s }
    name { "Cutlass - Akuma Paint" }

    association :user
  end
end
