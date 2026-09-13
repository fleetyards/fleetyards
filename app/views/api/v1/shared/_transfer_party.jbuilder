# frozen_string_literal: true

# A user or a fleet, told apart by `kind` rather than by which key is present.
if party.blank?
  json.null!
elsif party.is_a?(::Fleet)
  json.kind "fleet"
  json.name party.name
  json.slug party.slug
else
  json.kind "user"
  json.name party.username
  json.slug party.username
end
