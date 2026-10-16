# frozen_string_literal: true

json.cache! ["v3", model_paint] do
  json.partial!("api/v1/model_paints/base", model_paint:)
end
