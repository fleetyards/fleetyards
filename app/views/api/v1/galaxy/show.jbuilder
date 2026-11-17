# frozen_string_literal: true

json.systems @systems do |system|
  json.code system.code
  json.name system.name
  json.position system.position
  json.system_type system.system_type
  json.affiliations system.affiliations
  json.in_game system.in_game
end

json.tunnels @tunnels do |tunnel|
  json.entry_code tunnel.entry_system.code
  json.exit_code tunnel.exit_system.code
  json.size tunnel.size
  json.bidirectional tunnel.bidirectional
end
