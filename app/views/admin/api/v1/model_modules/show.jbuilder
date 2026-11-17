# frozen_string_literal: true

json.partial! "admin/api/v1/model_modules/model_module", model_module: @model_module
json.component_id @model_module.component&.id
