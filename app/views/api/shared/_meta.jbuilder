# frozen_string_literal: true

json.meta do
  json.pagination do
    json.partial! "api/shared/pagination", result: result
  end
end
