# frozen_string_literal: true

json.array! @models, partial: 'admin/api/v1/models/option', as: :model
