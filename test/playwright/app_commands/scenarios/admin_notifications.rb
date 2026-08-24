# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating admin_notifications scenario test data..."

admin_user = AdminUser.find_or_create_by!(username: "admin_notifications") do |u|
  u.email = "admin_notifications@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.super_admin = true
end

AdminNotificationExamples.create_for(admin_user)

Rails.logger.info "E2E: Created admin_notifications scenario test data"
