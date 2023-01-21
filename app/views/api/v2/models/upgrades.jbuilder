# frozen_string_literal: true

json.array! @model_upgrades, partial: "api/v2/model_upgrades/minimal", as: :model_upgrade
