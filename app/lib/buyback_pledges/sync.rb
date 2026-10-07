# frozen_string_literal: true

module BuybackPledges
  # Replaces a user's buy-back list with the one read from RSI. The RSI page is
  # the whole truth: a pledge that was bought back simply stops being listed, so
  # anything not in `items` goes.
  class Sync
    # The list replaces everything stored, so an entry that cannot be stored
    # would delete its own row while the sync reports success. One such entry
    # refuses the whole list instead.
    class InvalidSnapshot < StandardError; end

    ATTRIBUTES = %i[
      kind name upgraded reclaimed_on contained image_url
      upgrade_from_ship_id upgrade_to_ship_id upgrade_to_sku_id
    ].freeze

    attr_reader :user, :items

    def initialize(user, items)
      @user = user
      @items = items.map { |item| item.to_h.deep_transform_keys { |key| key.to_s.underscore.to_sym } }
    end

    def run
      rows = build_rows
      pledge_ids = rows.pluck(:rsi_pledge_id)

      # The user row as a mutex: two overlapping syncs would each delete against
      # their own list before either inserted, and leave the union of both.
      user.with_lock do
        existing_ids = user.buyback_pledges.pluck(:rsi_pledge_id)
        removed = user.buyback_pledges.where.not(rsi_pledge_id: pledge_ids).delete_all

        BuybackPledge.upsert_all(rows, unique_by: %i[user_id rsi_pledge_id]) if rows.any?

        {
          total: rows.size,
          added: (pledge_ids - existing_ids).size,
          removed:
        }
      end
    end

    # One row per pledge id: a duplicate inside one `upsert_all` is an error in
    # Postgres ("ON CONFLICT DO UPDATE command cannot affect row a second time").
    private def build_rows
      items.each do |item|
        next if item[:id].present? && item[:name].present? && BuybackPledge::KINDS.include?(item[:kind])

        raise InvalidSnapshot
      end

      items.map { |item| row(item) }.uniq { |row| row[:rsi_pledge_id] }
    end

    private def row(item)
      ATTRIBUTES.index_with { |attribute| item[attribute] }.merge(
        user_id: user.id,
        rsi_pledge_id: item[:id].to_s,
        upgraded: ActiveModel::Type::Boolean.new.cast(item[:upgraded]) || false,
        image_url: item[:image]
      )
    end
  end
end
