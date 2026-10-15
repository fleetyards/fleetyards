# frozen_string_literal: true

json.cache! ["v4", model, Manufacturer.artwork_version, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end

# Outside the cache: a crop that found nothing to cut settles the list without
# touching the model, so the cached fragment would go on saying it is pending.
json.media_processing model.media_processing if local_assigns.fetch(:extended, false)

# The module slots the game files give the hull, for an admin placing a module
# in one. Outside the cache too: a load adds slots without touching the model.
if local_assigns.fetch(:extended, false)
  json.module_slots model.hardpoints.where(category: :module, source: :game_files).order(:sc_name).pluck(:sc_name).uniq
end
