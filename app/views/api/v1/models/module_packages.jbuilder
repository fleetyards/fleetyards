# frozen_string_literal: true

json.array! @module_packages, partial: "api/v1/model_module_packages/model_module_package", as: :module_package
