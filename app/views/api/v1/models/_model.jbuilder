# frozen_string_literal: true

# The labels are localised (dates, number formats), so a fragment is only
# shared between readers of one locale.
json.cache! ["v3", model, ::ScData::Source.current, Manufacturer.artwork_version, local_assigns.fetch(:extended, false), I18n.locale] do
  json.partial!("api/v1/models/base", model:, extended: local_assigns.fetch(:extended, false))
end
