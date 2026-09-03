# frozen_string_literal: true

# One day's price for one item at one terminal.
#
# Written after each UEX sync, from what we hold rather than from what the feed
# listed: a terminal whose removal the syncer held back is still a price we are
# serving, so it belongs in the history too.
# == Schema Information
#
# Table name: item_price_snapshots
#
#  id          :uuid             not null, primary key
#  item_type   :string           not null
#  location    :string           not null
#  price       :decimal(15, 2)   not null
#  price_type  :integer          not null
#  recorded_on :date             not null
#  time_range  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  item_id     :uuid             not null
#
# Indexes
#
#  index_item_price_snapshots_on_item                  (item_type,item_id)
#  index_item_price_snapshots_on_item_and_day          (item_type,item_id,location,price_type,time_range,recorded_on) UNIQUE NULLS NOT DISTINCT
#  index_item_price_snapshots_on_item_and_recorded_on  (item_type,item_id,recorded_on)
#  index_item_price_snapshots_on_recorded_on           (recorded_on)
#
class ItemPriceSnapshot < ApplicationRecord
  belongs_to :item, polymorphic: true

  # Sourced from ItemPrice rather than retyped -- a snapshot that disagreed with
  # the table it is a copy of would be worse than no snapshot.
  enum :price_type, ItemPrice.price_types, validate: true
  enum :time_range, ItemPrice.time_ranges, validate: {allow_nil: true}

  scope :on_day, ->(day) { where(recorded_on: day) }
  scope :recorded_since, ->(day) { where(recorded_on: day..) }
  scope :oldest_first, -> { order(:recorded_on) }

  validates :location, presence: true
  validates :price, presence: true
  validates :recorded_on, presence: true
end
