# frozen_string_literal: true

json.array! @model_modules, partial: "api/v1/model_modules/model_module", as: :model_module
