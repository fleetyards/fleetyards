# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating notifications scenario test data..."

user = User.find_or_create_by!(username: "notifications") do |u|
  u.email = "notifications@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.confirmed_at = Time.current
end

NotificationExamples.create_for(user)

Rails.logger.info "E2E: Created notifications scenario test data"
