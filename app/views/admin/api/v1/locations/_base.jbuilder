# frozen_string_literal: true

json.partial! "api/v1/locations/base", location: location

json.sc_refs location.sc_refs
json.version location.version
