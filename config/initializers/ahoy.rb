# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:accept_language] = request.headers["Accept-Language"]
    super(data)
  end
end
# rubocop:enable Style/ClassAndModuleChildren

Ahoy.mask_ips = true
Ahoy.cookies = false
Ahoy.api = true
Ahoy.geocode = false
Ahoy.user_agent_parser = :device_detector
