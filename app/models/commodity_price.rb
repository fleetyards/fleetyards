# frozen_string_literal: true

# == Schema Information
#
# Table name: commodity_prices
#
#  id                :uuid             not null, primary key
#  confirmed         :boolean          default(FALSE)
#  price             :decimal(15, 2)
#  submitted_by      :uuid
#  time_range        :integer
#  type              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  shop_commodity_id :uuid
#
# Indexes
#
#  index_commodity_prices_on_shop_commodity_id  (shop_commodity_id)
#
class CommodityPrice < ApplicationRecord
  belongs_to :shop_commodity, touch: true

  belongs_to :submitter, class_name: 'User', foreign_key: 'submitted_by', inverse_of: false

  validates :price, presence: true
  validates :type, presence: true
  validates :shop_commodity, presence: true
end
