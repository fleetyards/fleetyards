json.id fleet_role.id
json.name fleet_role.name
json.slug fleet_role.slug
json.resource_access fleet_role.resource_access

if local_assigns.fetch(:extended, false)
  json.permanent fleet_role.permanent
  json.rank fleet_role.rank
  json.partial! "api/shared/dates", record: fleet_role
end
