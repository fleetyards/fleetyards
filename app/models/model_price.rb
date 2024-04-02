# == Schema Information
#
# Table name: model_prices
#
#  id           :uuid             not null, primary key
#  location     :string
#  location_url :string
#  price        :decimal(15, 2)
#  price_type   :integer
#  time_range   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  model_id     :uuid             not null
#
# Indexes
#
#  index_model_prices_on_model_id  (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id)
#
class ModelPrice < ApplicationRecord
  belongs_to :model

  enum price_type: {buy: 0, sell: 1, rental: 2}
  enum time_range: {"1-day": 0, "3-days": 1, "7-days": 2, "30-days": 3}

  validates :price_type, presence: true
  validates :time_range, presence: true, if: -> { rental? }
  validates :price, presence: true
end
