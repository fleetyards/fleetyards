# frozen_string_literal: true

json.array! @models, partial: 'api/v1/fleets/model', as: :model
