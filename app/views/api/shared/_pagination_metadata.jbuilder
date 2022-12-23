# frozen_string_literal: true

json.metadata do
  json.has_more !last_page?(scope)
  json.limit per_page(model)
  json.links do
    json.self request.url
    json.prev prev_url(scope)
    json.next next_url(scope)
  end
end
