# frozen_string_literal: true

# Narrows a catalogue to what one shop sells or rents, by the shop's slug: a
# shop's page lists its stock with the catalogue's own list. A subquery rather
# than a join, so an item with several prices at the shop comes back once.
module SoldAtShop
  extend ActiveSupport::Concern

  included do
    scope :sold_at_shop, ->(slug) {
      where(id: ItemPrice.joins(:shop).where(item_type: name, shops: {slug: slug.to_s.downcase}).select(:item_id))
    }
  end
end
