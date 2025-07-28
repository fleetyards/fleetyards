# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:accept_language] = request.headers["Accept-Language"]
    super
  end
end
# rubocop:enable Style/ClassAndModuleChildren

Ahoy.mask_ips = true
Ahoy.cookies = :none
Ahoy.api = true
Ahoy.geocode = false
Ahoy.user_agent_parser = :device_detector
