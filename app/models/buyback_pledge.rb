# frozen_string_literal: true

# == Schema Information
#
# Table name: buyback_pledges
#
#  id                   :uuid             not null, primary key
#  available            :boolean          default(TRUE), not null
#  contained            :string
#  details_synced_at    :datetime
#  image_url            :string
#  insurance_months     :integer
#  kind                 :string           not null
#  lifetime_insurance   :boolean          default(FALSE), not null
#  name                 :string           not null
#  price                :decimal(15, 2)
#  price_currency       :string
#  reclaimed_on         :date
#  upgraded             :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  rsi_pledge_id        :string           not null
#  upgrade_from_ship_id :integer
#  upgrade_to_ship_id   :integer
#  upgrade_to_sku_id    :integer
#  user_id              :uuid             not null
#
# Indexes
#
#  index_buyback_pledges_on_user_id_and_rsi_pledge_id  (user_id,rsi_pledge_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
# A pledge the user melted on RSI and could buy back, as listed on the RSI
# buy-back page. Kept apart from vehicles: none of these are ships the user owns.
class BuybackPledge < ApplicationRecord
  paginates_per 50
  max_paginates_per 200

  KINDS = %w[package ship upgrade paint addon other].freeze

  belongs_to :user

  validates :rsi_pledge_id, presence: true, uniqueness: {scope: :user_id}
  validates :name, presence: true
  validates :kind, inclusion: {in: KINDS}

  def self.ransackable_attributes(_auth_object = nil)
    %w[kind name]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
