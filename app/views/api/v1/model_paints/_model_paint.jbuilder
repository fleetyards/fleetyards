# frozen_string_literal: true

json.cache! ["v1", model_paint] do
  json.partial!("api/v1/model_paints/base", model_paint:)
end
