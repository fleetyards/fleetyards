# frozen_string_literal: true

json.vehicles @vehicles do |vehicle|
  json.id vehicle.id
  json.name vehicle.name
  json.serial vehicle.serial
  json.flagship vehicle.flagship
  if vehicle.image.attached?
    json.image do
      json.partial! "api/v1/shared/file", record: vehicle, attr: :image
    end
  end
  if vehicle.model_paint_picture&.store_image&.attached?
    json.paint_image do
      json.partial! "api/v1/shared/file", record: vehicle.model_paint_picture, attr: :store_image
    end
  end
end

json.friends do
  json.total @friends_total
  json.items @friends do |(user, count)|
    json.username user.username
    if user.avatar.attached?
      json.avatar do
        json.partial! "api/v1/shared/file", record: user, attr: :avatar
      end
    end
    json.count count
  end
end

json.fleets @fleets do |entry|
  fleet = entry[:fleet]
  json.id fleet.id
  json.fid fleet.fid
  json.name fleet.name
  json.slug fleet.slug
  if fleet.logo.attached?
    json.logo do
      json.partial! "api/v1/shared/file", record: fleet, attr: :logo
    end
  end
  json.total entry[:total]
  json.owners_total entry[:owners_total]
  json.members entry[:members]
end
