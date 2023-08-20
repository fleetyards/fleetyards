# frozen_string_literal: true

json.array! @results, partial: "api/v1/search/search", as: :result
