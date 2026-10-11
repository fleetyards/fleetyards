# frozen_string_literal: true

json.meta do
  json.pagination do
    json.partial! "api/shared/pagination", result: result, per_page_steps: local_assigns[:per_page_steps]
  end
end
