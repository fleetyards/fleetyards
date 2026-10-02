# frozen_string_literal: true

json.partial! "api/v1/locations/base", location: location

json.sc_refs location.sc_refs
# The build whose facts are shown, for the source being served: the row's own
# version is whichever source loaded it last.
json.version location.facts&.version || location.version
