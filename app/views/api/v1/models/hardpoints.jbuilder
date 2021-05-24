# frozen_string_literal: true

json.array! @hardpoints, partial: 'api/v1/models/hardpoint', as: :hardpoint
