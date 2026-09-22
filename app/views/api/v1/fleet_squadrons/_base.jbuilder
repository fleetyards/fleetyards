# frozen_string_literal: true

json.id fleet_squadron.id
json.name fleet_squadron.name
json.slug fleet_squadron.slug
json.short_description fleet_squadron.short_description
json.color fleet_squadron.color
json.team fleet_squadron.team

%i[icon logo].each do |attr|
  if fleet_squadron.public_send(attr).attached?
    json.set! attr do
      json.partial! "api/v1/shared/file", record: fleet_squadron, attr: attr
    end
  else
    json.set! attr, nil
  end
end

json.partial! "api/shared/dates", record: fleet_squadron
