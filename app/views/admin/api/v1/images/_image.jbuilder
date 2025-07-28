# frozen_string_literal: true

json.cache! ["v1", image] do
  json.partial!("admin/api/v1/images/base", image:)
end
