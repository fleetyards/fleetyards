# frozen_string_literal: true

json.array! @models, partial: 'api/v1/models/cargo_option', as: :model
