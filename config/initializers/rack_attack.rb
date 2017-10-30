# frozen_string_literal: true

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

limit_proc = proc do |req|
  if req.env['warden'].authenticate?(scope: :api_user)
    10_000
  else
    5000
  end
end

Rack::Attack.throttle('api', limit: limit_proc, period: 1.hour) do |req|
  if !req.path.match?(%r{^\/v\d+$}) &&
     !req.path.match?(%r{^\/v\d+\/docs$}) &&
     req.host.split('.').first == 'api' &&
     !(req.referer || '').match?(%r{^https:\/\/fleetyards\.net})
    req.ip
  end
end

Rack::Attack.throttled_response = lambda do |env|
  now = Time.zone.now
  match_data = env['rack.attack.match_data']

  headers = {
    'X-RateLimit-Limit' => match_data[:limit].to_s,
    'X-RateLimit-Remaining' => '0',
    'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_time.iso8601
  }

  [403, headers, [
    {
      code: 'rate_limit.exceeded',
      message: "API rate limit exceeded for #{env['rack.attack.match_discriminator']}"
    }.to_json
  ]]
end
