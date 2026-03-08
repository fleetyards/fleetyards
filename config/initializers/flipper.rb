require "flipper"
require "flipper/adapters/active_record"

Flipper.register(:testers) do |actor, _context|
  actor.respond_to?(:tester?) && actor.tester?
end

Flipper.register(:admins) do |actor, _context|
  actor.is_a? AdminUser
end

Rails.application.config.after_initialize do
  Flipper.add(:tools_travel_times)
  Flipper.add(:tools_cargo_grids)
  Flipper.add("hardpoints-v2")
  Flipper.add("oauth-discord")
  Flipper.add("oauth-github")
  Flipper.add("oauth-twitch")
  Flipper.add("oauth-google")
  Flipper.add("oauth-apple")
rescue ActiveRecord::StatementInvalid
  # Tables may not exist yet during db:create/db:migrate
  nil
end
