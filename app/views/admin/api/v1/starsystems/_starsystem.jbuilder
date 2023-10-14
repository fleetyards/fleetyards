# frozen_string_literal: true

json.cache! ["v1", starsystem, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/starsystems/base", starsystem:, extended: local_assigns.fetch(:extended, false))
end
