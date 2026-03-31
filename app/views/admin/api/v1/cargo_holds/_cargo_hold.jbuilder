# frozen_string_literal: true

json.cache! ["v1", cargo_hold] do
  json.partial!("admin/api/v1/cargo_holds/base", cargo_hold:)
end
