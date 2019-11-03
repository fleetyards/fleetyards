# frozen_string_literal: true

json.array! @weeks, partial: 'api/v1/roadmap/week', as: :week
