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

  # Seed default self-service settings
  %w[tools_travel_times tools_cargo_grids].each do |name|
    FeatureSetting.find_or_create_by(feature_name: name) do |fs|
      fs.self_service = true
    end
  end
rescue ActiveRecord::StatementInvalid
  # Tables may not exist yet during db:create/db:migrate
  nil
end
