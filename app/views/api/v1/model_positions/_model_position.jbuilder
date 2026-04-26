# frozen_string_literal: true

json.cache! ["v1", model_position] do
  json.partial!("api/v1/model_positions/base", model_position:)
end
