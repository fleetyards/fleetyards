# == Schema Information
#
# Table name: model_paints
#
#  id                      :uuid             not null, primary key
#  active                  :boolean          default(TRUE)
#  angled_view             :string
#  angled_view_height      :integer
#  angled_view_width       :integer
#  description             :string
#  fleetchart_image        :string
#  fleetchart_image_height :integer
#  fleetchart_image_width  :integer
#  hidden                  :boolean          default(TRUE)
#  last_pledge_price       :decimal(15, 2)
#  last_updated_at         :datetime
#  name                    :string
#  on_sale                 :boolean          default(FALSE)
#  pledge_price            :decimal(15, 2)
#  production_note         :string
#  production_status       :string
#  rsi_description         :string
#  rsi_name                :string
#  rsi_slug                :string
#  rsi_store_image         :string
#  rsi_store_image_height  :integer
#  rsi_store_image_width   :integer
#  rsi_store_url           :string
#  side_view               :string
#  side_view_height        :integer
#  side_view_width         :integer
#  slug                    :string
#  store_image             :string
#  store_image_height      :integer
#  store_image_width       :integer
#  store_images_updated_at :datetime
#  store_url               :string
#  top_view                :string
#  top_view_height         :integer
#  top_view_width          :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid
#  rsi_id                  :integer
#
FactoryBot.define do
  factory :model_paint do
    name { Faker::Name.name }
    model
    hidden { false }
    active { true }
  end
end
