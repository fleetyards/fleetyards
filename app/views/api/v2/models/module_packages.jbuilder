# frozen_string_literal: true

json.array! @module_packages, partial: "api/v2/model_module_packages/minimal", as: :module_package
