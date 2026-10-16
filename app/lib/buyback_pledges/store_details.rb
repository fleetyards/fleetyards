# frozen_string_literal: true

module BuybackPledges
  # Stores what the RSI buy-back detail page (or, for an upgrade, RSI's upgrade
  # price) says about pledges the list sync already stored. A detail for a
  # pledge the user does not have is skipped: the list may have moved on since.
  class StoreDetails
    attr_reader :user, :items

    def initialize(user, items)
      @user = user
      @items = items.map { |item| item.to_h.deep_transform_keys { |key| key.to_s.underscore.to_sym } }
    end

    def run
      synced_at = Time.current

      updated = BuybackPledge.transaction do
        items.uniq { |item| item[:id].to_s }.sum do |item|
          user.buyback_pledges.where(rsi_pledge_id: item[:id].to_s).update_all(
            price: item[:price],
            insurance_months: item[:insurance_months],
            lifetime_insurance: ActiveModel::Type::Boolean.new.cast(item[:lifetime_insurance]) || false,
            **ship_names(item),
            details_synced_at: synced_at,
            updated_at: synced_at
          )
        end
      end

      {updated:}
    end

    # A page read before ship names were sent says nothing about them, so the
    # stored ones stay, and an unknown pack stays queued for another read.
    private def ship_names(item)
      return {} unless item.key?(:ship_names)

      {ship_names: Array(item[:ship_names]).filter_map { |name| name.to_s.squish.presence }.uniq}
    end
  end
end
