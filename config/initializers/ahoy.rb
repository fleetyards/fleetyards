# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class Ahoy::Store < Ahoy::DatabaseStore
end
# rubocop:enable Style/ClassAndModuleChildren

Ahoy.mask_ips = true
Ahoy.cookies = false
Ahoy.api = true
Ahoy.geocode = false
Ahoy.user_agent_parser = :device_detector
