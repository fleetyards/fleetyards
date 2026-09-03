# frozen_string_literal: true

module Uex
  # Reconciling a UEX snapshot against the prices we hold is the same problem
  # whether the rows are ships or cargo: apply what the feed lists, and work out
  # which of our leftovers are genuinely gone rather than merely missing from a
  # short answer. Including classes supply ITEM_TYPE and build their own Result.
  module PriceSnapshot
    # How much of a terminal's stock it must still list before we believe its
    # omissions. A shop dropping over half its stock between two daily runs is
    # not plausible churn; a feed that came back short looks exactly like that.
    MIN_TERMINAL_RETENTION = 0.5

    Counts = Struct.new(:created, :updated, :removed, :skipped_removals)

    private def persist_prices(desired, live:)
      counts = Counts.new(0, 0, 0, 0)

      ItemPrice.transaction do
        held = ItemPrice.where(item_type: self.class::ITEM_TYPE).to_a
        held_per_location = held.group_by(&:location).transform_values(&:size)
        listed_per_location = desired.values.group_by { |row| row[:location] }.transform_values(&:size)

        # Whatever is left in here once every desired row has claimed its match
        # is a location UEX no longer lists.
        unclaimed = held.index_by do |item_price|
          [item_price.item_id, item_price.price_type, item_price.location, item_price.time_range]
        end

        desired.each do |key, attributes|
          item_price = unclaimed.delete(key)

          if item_price.blank?
            ItemPrice.create!(attributes)
            counts.created += 1
            next
          end

          item_price.assign_attributes(attributes.slice(:price, :location_url))
          next unless item_price.changed?

          item_price.save!
          counts.updated += 1
        end

        deletable, ambiguous = unclaimed.values.partition do |item_price|
          deletable?(item_price.location, listed: listed_per_location, held: held_per_location, live:)
        end

        # Upserts have already applied either way, so fresh prices still land and
        # only the destructive half is held back. A later whole snapshot reconciles.
        counts.skipped_removals = ambiguous.size
        report_skipped_removals(ambiguous, held.size) if ambiguous.any?

        counts.removed = ItemPrice.where(id: deletable.map(&:id)).destroy_all.size
      end

      counts
    end

    # Copies what we now hold into the day's history.
    #
    # Deliberately outside `persist_prices` and its transaction: a removal pass
    # that raises must not take the day's history down with it, and the rows are
    # worth keeping either way. Reading back from `ItemPrice` rather than from
    # the desired set is the same argument -- a terminal whose removal was held
    # back is still a price we serve, so it belongs in the history.
    #
    # Delete-then-insert rather than an upsert: a second run on the same day is
    # a correction, and replacing the day wholesale also drops rows for prices
    # that have since gone away.
    private def record_price_history(recorded_on: Date.current)
      now = Time.current

      rows = ItemPrice.where(item_type: self.class::ITEM_TYPE).map do |item_price|
        {
          item_type: item_price.item_type,
          item_id: item_price.item_id,
          location: item_price.location,
          price_type: ItemPrice.price_types.fetch(item_price.price_type),
          time_range: item_price.time_range && ItemPrice.time_ranges.fetch(item_price.time_range),
          price: item_price.price,
          recorded_on: recorded_on,
          created_at: now,
          updated_at: now
        }
      end

      ItemPriceSnapshot.transaction do
        ItemPriceSnapshot.where(item_type: self.class::ITEM_TYPE, recorded_on:).delete_all
        ItemPriceSnapshot.insert_all(rows) if rows.any?
      end

      # The syncers only run in production, where nobody is watching the return
      # value. A day that recorded nothing has to be visible in the log.
      Rails.logger.info(
        "[#{self.class.name}] recorded #{rows.size} #{self.class::ITEM_TYPE.downcase} price snapshots for #{recorded_on}"
      )

      rows.size
    end

    # Decided per terminal, because that is the only granularity at which the
    # question is answerable. A terminal gone from the terminals feed has closed,
    # so its rows go. Otherwise the test is whether it reported at anything like
    # its usual volume: a shop discontinuing a line or two still lists the rest,
    # whereas a truncated feed shows up as a terminal that suddenly lists a
    # fraction of what we hold for it — or nothing at all. Below the retention
    # floor we keep its rows and report rather than guess.
    private def deletable?(location, listed:, held:, live:)
      return true if live.exclude?(location)

      listed.fetch(location, 0) >= held.fetch(location, 0) * MIN_TERMINAL_RETENTION
    end

    private def report_skipped_removals(preserved, held_before)
      message = "UEX snapshot omitted #{preserved.size} of #{held_before} #{self.class::ITEM_TYPE.downcase} prices at " \
        "#{preserved.map(&:location).uniq.sort.join(", ")}; kept them and applied updates only"

      Rails.logger.warn("[#{self.class.name}] #{message}")
      Appsignal.report_error(Uex::Error.new(message))
    end

    # `contact_url` is whatever a UEX contributor typed. Anything that is not a
    # web link is dropped rather than stored: `ItemPrice` rejects it, and one odd
    # row must not fail a validation and take the whole snapshot down with it.
    private def web_url(value)
      url = value.to_s.strip

      url if url.match?(%r{\Ahttps?://}i)
    end

    # No feed is ever legitimately empty. An empty one still arrives as HTTP 200
    # with status "ok", and taking it at face value would read as "every location
    # closed" and delete the lot.
    private def require_rows(feed, rows)
      return rows if rows.present?

      raise Uex::Error, "UEX returned no usable rows for #{feed}; refusing to sync a snapshot that would delete live prices"
    end
  end
end
