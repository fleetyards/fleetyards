# frozen_string_literal: true

module Rsi
  # Records which ships RSI has ever sold an upgrade (CCU) out of or into. The
  # store lists only the upgrades on sale today, but every upgrade a synced
  # hangar holds or a buy-back offers was sold at some point, and most come
  # back for a sale, so a ship once seen keeps its date.
  class CcuCatalogue
    def run(now: Time.current)
      seen = pairs
      sources = seen.map(&:first).compact.uniq
      targets = seen.map(&:last).compact.uniq

      mark(sources, :ccu_source_seen_at, now)
      mark(targets, :ccu_target_seen_at, now)
      restrict(seen, now)
    end

    # An edition upgrade, such as to a ship's Executive Edition, names one
    # model at both ends and says nothing about upgrades between ships.
    private def pairs
      (hangar_pairs + buyback_pairs).reject { |from, to| from && from == to }
    end

    private def hangar_pairs
      titles = HangarPledgeItem.upgrades.distinct.pluck(:name) + BuybackPledge.where(kind: "upgrade").distinct.pluck(:name)
      names = titles.map { |title| UpgradeTitles.ship_names(title) }.select { |pair| pair.size == 2 }
      models = UpgradeTitles.models_by_name(names.flatten)

      names.map { |from, to| [models[from]&.id, models[to]&.id] }
    end

    # A buy-back names both ships by their RSI ids, where the title alone could
    # not be matched.
    private def buyback_pairs
      ids = BuybackPledge.where(kind: "upgrade").distinct.pluck(:upgrade_from_ship_id, :upgrade_to_ship_id)
      models = Model.where(rsi_id: ids.flatten.compact.uniq).pluck(:rsi_id, :id).to_h

      ids.map { |from, to| [models[from], models[to]] }
    end

    # A ship every seen upgrade reaches from a variant of its own hull is
    # reachable only from those; one seen from any other ship is open to all.
    # Worked out again on every run, so a later upgrade lifts the limit.
    private def restrict(seen, now)
      chassis = Model.where.not(rsi_chassis_id: nil).pluck(:id, :rsi_chassis_id).to_h
      # An upgrade from a ship that could not be named is from some other ship.
      limits = seen.select(&:last).group_by(&:last).filter_map do |target, entries|
        from = entries.map(&:first).uniq
        [target, from.sort] if chassis[target] && from.all? { |id| id && chassis[id] == chassis[target] }
      end.to_h

      Model.where.not(ccu_target_source_ids: nil).where.not(id: limits.keys)
        .update_all(ccu_target_source_ids: nil, updated_at: now)
      limits.each do |target, from|
        Model.where(id: target).where("ccu_target_source_ids IS DISTINCT FROM ARRAY[?]::uuid[]", from)
          .update_all(ccu_target_source_ids: from, updated_at: now)
      end
    end

    # Bumps updated_at with the date, so cached JSON of a ship shows it.
    private def mark(ids, column, now)
      return if ids.empty?

      Model.where(id: ids).where(column => nil).update_all(column => now, :updated_at => now)
    end
  end
end
