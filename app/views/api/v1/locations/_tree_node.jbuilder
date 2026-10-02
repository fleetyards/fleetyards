# frozen_string_literal: true

json.location do
  json.partial! "api/v1/locations/link", location: node.location
  json.shown_on_starmap node.location.shown_on_starmap
  json.partial! "api/v1/locations/appearance", location: node.location
end

json.counts node.counts do |count|
  json.kind count[:kind]
  json.count count[:count]
end

json.lagrange_points node.lagrange_points do |point|
  json.partial! "api/v1/locations/link", location: point
end

json.gateways node.gateways do |gateway|
  json.partial! "api/v1/locations/link", location: gateway
end

json.children node.children do |child|
  json.partial! "api/v1/locations/tree_node", node: child
end
