# frozen_string_literal: true

json.array! @model_upgrades, partial: "api/v1/model_upgrades/model_upgrade", as: :model_upgrade
