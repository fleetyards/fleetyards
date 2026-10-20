# frozen_string_literal: true

prerequisites = mission.facts&.prerequisites.to_a
missions = mission.prerequisite_missions(prerequisites)

json.prerequisites prerequisites do |prerequisite|
  json.kind prerequisite.kind
  json.min prerequisite.min
  json.max prerequisite.max
  json.org_name prerequisite.org_name
  json.org_key prerequisite.org_key
  json.min_standing prerequisite.min_standing
  json.max_standing prerequisite.max_standing
  json.excluded prerequisite.excluded
  json.count prerequisite.count
  json.includes_self prerequisite.includes_self

  # The missions that grant what this one asks for, as far as the catalogue
  # offers them.
  json.missions prerequisite.mission_refs.filter_map { |ref| missions[ref] } do |linked|
    json.id linked.id
    json.name linked.name
    json.slug linked.slug
  end
end
