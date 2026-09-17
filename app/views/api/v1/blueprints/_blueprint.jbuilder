# frozen_string_literal: true

# `ScData::Source.current` rather than its version alone: a fact is read off the
# build the request is for, so a cached fragment has to move when the source
# does, not only when the version string does.
json.cache! ["v1", blueprint, ::ScData::Source.current] do
  json.partial! "api/v1/blueprints/base", blueprint:
end
