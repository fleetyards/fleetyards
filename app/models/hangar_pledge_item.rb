# frozen_string_literal: true

# A paint or a piece of hangar flair in the user's RSI hangar, as read by the
# hangar sync. Neither becomes a vehicle, so both are kept as RSI lists them.
class HangarPledgeItem < ApplicationRecord
  paginates_per 50
  max_paginates_per 200

  KINDS = %w[paint flair].freeze

  belongs_to :user

  validates :rsi_pledge_id, :name, presence: true
  validates :kind, inclusion: {in: KINDS}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}

  scope :paints, -> { where(kind: "paint") }
  scope :flair, -> { where(kind: "flair") }
  scope :with_value, -> { where(pledge_value: 0.01..) }

  # Newest pledge first, the order RSI lists the hangar in. Pledge ids grow
  # over time, so they order pledges created on the same day, and any pledge
  # whose date could not be read.
  def self.hangar_order
    Arel.sql(<<~SQL.squish)
      hangar_pledge_items.pledge_created_on DESC NULLS LAST,
      length(hangar_pledge_items.rsi_pledge_id) DESC,
      hangar_pledge_items.rsi_pledge_id DESC,
      hangar_pledge_items.name ASC,
      hangar_pledge_items.id ASC
    SQL
  end

  # Melting returns what the whole pledge is worth, so an item has a melt value
  # of its own only when it is all the pledge holds. RSI lists a poster held
  # twice as two items, which the sync stores as one row.
  def standalone?
    pledge_item_count.present? && pledge_item_count == quantity
  end

  def melt_value
    pledge_value if standalone?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[meltable name]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[with_value]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
