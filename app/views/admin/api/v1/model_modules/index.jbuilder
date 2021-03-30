# frozen_string_literal: true

json.array! @model_modules, partial: 'admin/api/v1/model_modules/minimal', as: :model_module
