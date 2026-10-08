# frozen_string_literal: true

# One day's price for one item at one terminal.
#
# Written after each UEX sync, from what we hold rather than from what the feed
# listed: a terminal whose removal the syncer held back is still a price we are
# serving, so it belongs in the history too.
class ItemPriceSnapshot < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :terminal, optional: true

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
