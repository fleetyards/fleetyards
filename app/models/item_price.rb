# == Schema Information
#
# Table name: item_prices
#
#  id           :uuid             not null, primary key
#  item_type    :string           not null
#  location     :string
#  location_url :string
#  price        :decimal(15, 2)
#  price_type   :integer
#  time_range   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  item_id      :uuid             not null
#
# Indexes
#
#  index_item_prices_on_item  (item_type,item_id)
#
class ItemPrice < ApplicationRecord
  belongs_to :item, polymorphic: true

  enum :price_type, {buy: 0, sell: 1, rental: 2}, validate: true
  enum :time_range, {"1-day": 0, "3-days": 1, "7-days": 2, "30-days": 3}, validate: {allow_nil: true}

  validates :time_range, presence: true, if: -> { rental? }
  validates :price, presence: true
  validates :location, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "item_id", "item_type", "location"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["item"]
  end
end
