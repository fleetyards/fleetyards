require "flipper"
require "flipper/adapters/active_record"

Flipper.register(:testers) do |actor, _context|
  actor.respond_to?(:tester?) && actor.tester?
end

Flipper.register(:admins) do |actor, _context|
  actor.is_a? AdminUser
end
