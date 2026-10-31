# frozen_string_literal: true

# The star systems the contract is offered in. The same title is offered as its
# own contract in each system, and this is what tells those apart.
json.systems mission.systems do |system|
  json.partial! "api/v1/locations/link", location: system
end
