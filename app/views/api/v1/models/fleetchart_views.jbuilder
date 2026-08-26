# frozen_string_literal: true

json.array! @models, partial: "api/v1/models/fleetchart_view", as: :model
