# frozen_string_literal: true

# The labels are localised (dates, number formats), so a fragment is only
# shared between readers of one locale.
stock_stat = LoadoutStat.for_environment(model.loadout_stats)

json.cache! ["v13", model, model.facts, stock_stat, ::ScData::Source.current, Manufacturer.artwork_version, local_assigns.fetch(:extended, false), I18n.locale] do
  json.partial!("api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
  json.partial!("api/v1/vehicles/weapons", stat: stock_stat)
end
