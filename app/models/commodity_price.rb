# frozen_string_literal: true

# == Schema Information
#
# Table name: commodity_prices
#
#  id                :uuid             not null, primary key
#  confirmed         :boolean          default(FALSE)
#  price             :decimal(15, 2)
#  submission_count  :integer          default(0)
#  submitters        :string
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
  REQUIRED_SUBMISSION_COUNT_FOR_AUTO_CONFIRM = 2

  belongs_to :shop_commodity, touch: true

  validates :price, presence: true
  validates :type, presence: true

  serialize :submitters, Array

  before_save :check_submissions_for_auto_confirm

  def users
    submitters.map do |submitter_id|
      User.find_by(id: submitter_id)
    end
  end

  def check_submissions_for_auto_confirm
    return if submission_count < REQUIRED_SUBMISSION_COUNT_FOR_AUTO_CONFIRM

    self.confirmed = true
  end

  def confirm!
    update!(confirmed: true)
  end

  def confirm
    update(confirmed: true)
  end
end
