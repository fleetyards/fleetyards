# frozen_string_literal: true

json.cache! ["v1", image] do
  json.partial!("api/v1/images/base", image:, extended: local_assigns.fetch(:extended, false))
end
