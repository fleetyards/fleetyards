# frozen_string_literal: true

json.array! @model_module_packages, partial: 'api/v1/model_module_packages/minimal', as: :model_module_package
