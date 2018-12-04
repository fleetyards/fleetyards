# frozen_string_literal: true

json.array! @model_modules, partial: 'api/v1/model_modules/minimal', as: :model_module
