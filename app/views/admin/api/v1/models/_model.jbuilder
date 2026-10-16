# frozen_string_literal: true

json.cache! ["v7", model, model.facts, Manufacturer.artwork_version, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end

# Outside the cache: a crop that found nothing to cut settles the list without
# touching the model, so the cached fragment would go on saying it is pending.
json.media_processing model.media_processing if local_assigns.fetch(:extended, false)

# The module slots the hull has in the build being served, for an admin placing
# a module in one. Outside the cache as well: a new build only writes build rows
# for the slots it keeps, and switching the served build writes nothing, so
# neither touches the model the fragment is keyed on.
if local_assigns.fetch(:extended, false)
  json.module_slots model.hardpoints.in_build.where(category: :module, source: :game_files)
    .where.not(sc_name: nil).distinct.order(:sc_name).pluck(:sc_name)
end
