# frozen_string_literal: true

json.array! @variants, partial: "api/v1/models/model", as: :model
