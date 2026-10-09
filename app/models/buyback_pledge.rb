# frozen_string_literal: true

# A pledge the user melted on RSI and could buy back, as listed on the RSI
# buy-back page. Kept apart from vehicles: none of these are ships the user owns.
class BuybackPledge < ApplicationRecord
  paginates_per 50
  max_paginates_per 200

  KINDS = %w[package ship upgrade paint addon other].freeze

  DEFAULT_SORTING_PARAMS = ["reclaimed_on desc"].freeze
  ALLOWED_SORTING_PARAMS = [
    "reclaimedOn asc", "reclaimedOn desc", "name asc", "name desc", "price asc", "price desc"
  ].freeze

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

  INSURANCE_MONTHS = 1..9999

  # Insurance is read from a pledge's detail page, so a pledge whose details
  # were never synced has unknown insurance, not none. Upgrades have no detail
  # page and carry no insurance.
  INSURANCE_KNOWN_SQL = "(buyback_pledges.details_synced_at IS NOT NULL OR buyback_pledges.kind = 'upgrade')"

  # "lifetime", "none" or a number of months, any of which matches. A lifetime
  # pledge never matches a number. Values that are none of these match nothing,
  # so a typo empties the list instead of quietly ignoring the filter.
  scope :insurance_in, ->(*values) {
    values = values.flatten.map(&:to_s)
    months = values.grep(/\A\d{1,4}\z/).map(&:to_i).select { |value| INSURANCE_MONTHS.cover?(value) }
    not_lifetime = arel_table[:lifetime_insurance].eq(false)

    conditions = []
    conditions << arel_table[:lifetime_insurance].eq(true) if values.include?("lifetime")
    if values.include?("none")
      no_months = arel_table[:insurance_months].eq(nil).or(arel_table[:insurance_months].eq(0))
      conditions << not_lifetime.and(no_months).and(Arel.sql(INSURANCE_KNOWN_SQL))
    end
    conditions << not_lifetime.and(arel_table[:insurance_months].in(months)) if months.any?

    conditions.empty? ? none : where(conditions.reduce(:or))
  }

  # The values `insurance_in` can match within this relation.
  def self.insurance_terms
    rows = distinct.pluck(:lifetime_insurance, :insurance_months, Arel.sql(INSURANCE_KNOWN_SQL))

    {
      months: rows.filter_map { |lifetime, months, _known| months if !lifetime && INSURANCE_MONTHS.cover?(months) }
        .uniq.sort.reverse,
      lifetime: rows.any? { |lifetime, _months, _known| lifetime },
      none: rows.any? { |lifetime, months, known| !lifetime && known && (months.nil? || months.zero?) }
    }
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[kind name price reclaimed_on]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[upgrade_from_model upgrade_to_model]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[price_in insurance_in]
  end

  # Ransack would otherwise read "1" as true, and drop a one-month filter.
  def self.ransackable_scopes_skip_sanitize_args
    %i[insurance_in]
  end
end
