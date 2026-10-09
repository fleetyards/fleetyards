# frozen_string_literal: true

module HangarPledgeItems
  # Replaces a user's paints and hangar flair with the ones a hangar sync read.
  # The pledge list is the whole truth: a melted or gifted pledge simply stops
  # being listed, so anything not in `items` goes.
  class Sync
    KINDS_BY_ITEM_TYPE = {"skin" => "paint", "flair" => "flair"}.freeze

    attr_reader :user, :items, :kinds

    # The kind an item would be stored as, or nil for one it cannot store.
    def self.kind_for(item)
      kind = KINDS_BY_ITEM_TYPE[item[:type].to_s]
      kind if item[:id].present? && item[:name].present?
    end

    # `kinds` the user chose not to sync are left exactly as stored, not
    # emptied: switching paints off is no statement that they are gone.
    def initialize(user, items, kinds: HangarPledgeItem::KINDS)
      @user = user
      @kinds = kinds
      @items = items.select { |item| kinds.include?(self.class.kind_for(item)) }
    end

    # The ids stored for each kind it synced.
    def run
      return {} if kinds.empty?

      rows = build_rows

      # The user row as a mutex: two overlapping syncs would each delete against
      # their own list before either inserted, and leave the union of both.
      user.with_lock do
        kept = if rows.any?
          HangarPledgeItem.upsert_all(
            rows,
            unique_by: :index_hangar_pledge_items_on_user_kind_pledge_name,
            returning: %w[id kind]
          ).to_a
        else
          []
        end

        user.hangar_pledge_items.where(kind: kinds).where.not(id: kept.pluck("id")).delete_all

        kinds.index_with { |kind| kept.select { |row| row["kind"] == kind }.pluck("id") }
      end
    end

    # A pledge can hold the same poster twice, which RSI lists as two items.
    private def build_rows
      items.group_by { |item| [KINDS_BY_ITEM_TYPE[item[:type].to_s], item[:id].to_s, item[:name].strip] }
        .map do |(kind, rsi_pledge_id, name), group|
          {
            user_id: user.id,
            kind:,
            rsi_pledge_id:,
            name:,
            quantity: group.size,
            image_url: group.filter_map { |item| item[:image].presence }.first,
            pledge_name: group.first[:pledge_name].presence,
            pledge_value: group.first[:pledge_value].presence,
            pledge_item_count: group.first[:pledge_item_count].presence,
            pledge_created_on: group.first[:pledge_created_on].presence,
            meltable: ActiveModel::Type::Boolean.new.cast(group.first[:meltable]) || false
          }
        end
    end
  end
end
