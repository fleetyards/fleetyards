# frozen_string_literal: true

module Rsi
  # Records which ships RSI has ever sold an upgrade (CCU) out of or into. The
  # store lists only the upgrades on sale today, but every upgrade a synced
  # hangar holds or a buy-back offers was sold at some point, and most come
  # back for a sale, so a ship once seen keeps its date.
  class CcuCatalogue
    def run(now: Time.current)
      sources, targets = pairs.transpose.map { |ids| ids.to_a.compact.uniq }

      mark(sources, :ccu_source_seen_at, now)
      mark(targets, :ccu_target_seen_at, now)
    end

    private def pairs
      hangar_pairs + buyback_pairs
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

    # Bumps updated_at with the date, so cached JSON of a ship shows it.
    private def mark(ids, column, now)
      return if ids.empty?

      Model.where(id: ids).where(column => nil).update_all(column => now, :updated_at => now)
    end
  end
end
