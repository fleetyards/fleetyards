# encoding: utf-8
# frozen_string_literal: true

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

limit_proc = proc do |req|
  if req.env['warden'].authenticate?(scope: :api_user)
    5000
  else
    100
  end
end

Rack::Attack.throttle('api', limit: limit_proc, period: 1.hour) do |req|
  return false unless req.host.split('.').first == 'api'
  req.ip
end

Rack::Attack.throttled_response = lambda do |env|
  now = Time.zone.now
  match_data = env['rack.attack.match_data']

  headers = {
    'X-RateLimit-Limit' => match_data[:limit].to_s,
    'X-RateLimit-Remaining' => '0',
    'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
  }

  [403, headers, ["Rate Limit exceeded\n"]]
end
