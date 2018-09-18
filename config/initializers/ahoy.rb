class Ahoy::Store < Ahoy::DatabaseStore
end

Ahoy.mask_ips = true
Ahoy.cookies = false
Ahoy.api = true
Ahoy.user_agent_parser = :device_detector
