# frozen_string_literal: true

json.array! @hardpoints, partial: 'api/v2/models/hardpoint', as: :hardpoint
