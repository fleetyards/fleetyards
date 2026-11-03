# frozen_string_literal: true

Rack::Attack.cache.store =
  if Rails.env.test?
    ActiveSupport::Cache::MemoryStore.new
  else
    ActiveSupport::Cache::RedisCacheStore.new(
      url: Rails.configuration.redis.url,
      db: Rails.configuration.redis.rack_attack_db,
      namespace: "rack-attack"
    )
  end

client_ip = ->(req) { (req.get_header("action_dispatch.remote_ip") || req.ip).to_s }

# Read straight from the session rather than through Warden: fetching the user
# here would cache it for the request and skip Devise's fetch callbacks, the
# timeout check among them, when the controller authenticates later.
#
# Loading the session commits it again on the way out (`expire_after` forces
# it), which on a 429 or a 404 would hand back a cookie that can overwrite a
# sign-in still in flight. It is left unwritten here, as Api::BaseController
# does, and a sign-in in the controller turns writing back on.
#
# An OAuth app is counted apart from its user's own session, so an app that
# polls hard spends its own budget rather than locking the user out of the site.
account_bucket = lambda do |req|
  return req.env["fleetyards.rate_limit_account"] if req.env.key?("fleetyards.rate_limit_account")

  req.env["fleetyards.rate_limit_account"] = begin
    token = Doorkeeper::OAuth::Token.authenticate(
      ActionDispatch::Request.new(req.env), *Doorkeeper.config.access_token_methods
    )
    if token
      "oauth:#{token.application_id}:#{token.resource_owner_id}" if token.accessible?
    else
      user_key = req.session["warden.user.user.key"]
      req.session_options[:skip] = true
      user_id = user_key&.first&.first
      "user:#{user_id}" if user_id
    end
  end
end

files_path = ->(req) { req.path.start_with?("#{ActiveStorage.routes_prefix}/") }

# A signed-in account is counted on its own, so a household or office behind one
# address does not share a single budget with every device on it.
Rack::Attack.throttle("api", limit: ->(req) { account_bucket.call(req) ? 10_000 : 5000 }, period: 1.hour) do |req|
  if !req.path.match?(%r{^/v\d+$}) &&
      !req.path.match?(%r{^/v\d+/docs$}) &&
      !files_path.call(req) &&
      req.host.split(".").first == "api"
    account_bucket.call(req) || client_ip.call(req)
  end
end

# Every image is its own redirect, so one hangar page can cost hundreds of
# requests. They get a budget of their own, sized for browsing, which still
# stops a scraper walking the whole gallery.
Rack::Attack.throttle("files", limit: 20_000, period: 1.hour) do |req|
  client_ip.call(req) if files_path.call(req)
end

# Registering an OAuth application is a deliberate act nobody performs in bulk,
# and the blanket API throttle above allows thousands an hour. This does not stop
# somebody signing up for fresh accounts -- nothing here would -- it stops one
# account or one address producing a review queue in a single burst.
Rack::Attack.throttle("oauth-application-registration", limit: 5, period: 1.hour) do |req|
  if req.post? &&
      req.path.match?(%r{^/v\d+/oauth-applications/?$}) &&
      req.host.split(".").first == "api"
    (req.get_header("action_dispatch.remote_ip") || req.ip).to_s
  end
end

# Ko-fi posts one request per payment, which at any plausible volume is a
# handful a day. The endpoint is unauthenticated by nature -- the token is in
# the body, so a wrong one still costs a JSON parse -- and this caps what that
# is worth to anyone who finds the URL.
Rack::Attack.throttle("kofi-webhook", limit: 60, period: 1.hour) do |req|
  if req.path == "/kofi/webhook" && req.post?
    (req.get_header("action_dispatch.remote_ip") || req.ip).to_s
  end
end

Rack::Attack.throttled_response_retry_after_header = true

Rack::Attack.throttled_responder = lambda do |request|
  now = Time.zone.now
  match_data = request.env["rack.attack.match_data"] || {}

  headers = {
    "X-RateLimit-Limit" => match_data[:limit].to_s,
    "X-RateLimit-Remaining" => "0",
    "X-RateLimit-Reset" => (now + (match_data[:period] - (now.to_i % match_data[:period]))).iso8601
  }

  [429, headers, [
    {
      code: "rate_limit.exceeded",
      message: "API rate limit exceeded for #{request.env["rack.attack.match_discriminator"]}"
    }.to_json
  ]]
end
