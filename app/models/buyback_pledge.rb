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
  belongs_to :upgrade_from_model, class_name: "Model", primary_key: :rsi_id,
    foreign_key: :upgrade_from_ship_id, optional: true, inverse_of: false
  belongs_to :upgrade_to_model, class_name: "Model", primary_key: :rsi_id,
    foreign_key: :upgrade_to_ship_id, optional: true, inverse_of: false

  validates :rsi_pledge_id, presence: true, uniqueness: {scope: :user_id}
  validates :name, presence: true
  validates :kind, inclusion: {in: KINDS}

  # In USD, like every price here. Buying an upgrade back costs what the
  # upgrade costs today, the difference between both ships' store prices.
  # Ours follow RSI's store, so it is computed rather than read from RSI and
  # stored.
  def upgrade_price
    return unless kind == "upgrade"

    from_price = upgrade_from_model&.pledge_price
    to_price = upgrade_to_model&.pledge_price
    return if from_price.nil? || to_price.nil?

    to_price - from_price
  end

  # The price the list shows, `upgrade_price` included, so a filter matches it.
  def self.price_sql
    ship_price = ->(column) {
      "(SELECT models.pledge_price FROM models WHERE models.rsi_id = buyback_pledges.#{column} LIMIT 1)"
    }

    <<~SQL.squish
      CASE WHEN buyback_pledges.kind = 'upgrade'
        THEN #{ship_price.call(:upgrade_to_ship_id)} - #{ship_price.call(:upgrade_from_ship_id)}
        ELSE buyback_pledges.price
      END
    SQL
  end

  ransacker(:price) { Arel.sql(price_sql) }

  # Preset ranges such as "25-50", "-25" or "1000-", any of which matches.
  scope :price_in, ->(*ranges) {
    conditions = ranges.flatten.filter_map do |range|
      from, to = range.to_s.split("-", 2)
      next if from.blank? && to.blank?

      bounds = []
      bounds << sanitize_sql_array(["#{price_sql} >= ?", from.to_i]) if from.present?
      bounds << sanitize_sql_array(["#{price_sql} < ?", to.to_i]) if to.present?
      "(#{bounds.join(" AND ")})"
    end

    conditions.empty? ? all : where(conditions.join(" OR "))
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[kind name price]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[upgrade_from_model upgrade_to_model]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[price_in]
  end
end
