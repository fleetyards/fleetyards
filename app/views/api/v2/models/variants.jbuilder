# frozen_string_literal: true

json.array! @variants, partial: "api/v2/models/minimal", as: :model
