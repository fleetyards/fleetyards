# frozen_string_literal: true

json.models @models, partial: "api/v1/models/fleetchart_model", as: :model
json.module_packages @module_packages, partial: "api/v1/model_module_packages/base", as: :module_package

json.items @vehicles do |vehicle|
  json.id vehicle.id
  json.name vehicle.name if vehicle.name_visible?
  json.model_id vehicle.model_id
  json.module_package_id vehicle.module_package_id if vehicle.module_package_id.present?

  unless vehicle.user.hide_owner?
    json.username vehicle.user.username
    json.user_display_name vehicle.user.display_name if vehicle.user.display_name.present?
  end

  squadron = @squadrons_by_user[vehicle.user_id]

  if squadron
    json.squadron do
      json.id squadron.id
      json.name squadron.name
      json.slug squadron.slug
      json.color squadron.color
    end
  end
end
