# frozen_string_literal: true

json.array! @model_modules, partial: 'api/v2/model_modules/minimal', as: :model_module
