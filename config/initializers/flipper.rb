require "flipper"
require "flipper/adapters/active_record"

Rails.application.config.flipper.actor_limit = nil

Flipper.register(:testers) do |actor, _context|
  actor.respond_to?(:tester?) && actor.tester?
end

Flipper.register(:maintainers) do |actor, _context|
  actor.respond_to?(:maintainer?) && actor.maintainer?
end

Flipper.register(:admins) do |actor, _context|
  actor.is_a? AdminUser
end
