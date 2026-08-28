# You can setup your Rails state here
require "factory_bot_rails"

Rails.logger.info "E2E: Creating notifications_bulk scenario test data..."

user = User.find_or_create_by!(username: "notifications") do |u|
  u.email = "notifications@test.com"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.confirmed_at = Time.current
end

# More than one page of them on purpose: selecting the page is only half of
# what the bulk bar does, and "select all matching" has nothing to prove until
# there is something behind the page.
(Notification.default_per_page + 5).times do |index|
  occurred_at = index.minutes.ago

  Notification.create!(
    user:,
    notification_type: :hangar_create,
    title: format("Bulk notification %02d", index + 1),
    icon: "fa-duotone fa-warehouse",
    created_at: occurred_at,
    updated_at: occurred_at
  )
end

# So the archive tab has something to draw: an empty tab renders the placeholder
# instead of the list, which would hide the bulk bar for the wrong reason.
2.times do |index|
  archived_at = (index + 1).hours.ago

  Notification.create!(
    user:,
    notification_type: :hangar_destroy,
    title: format("Archived notification %02d", index + 1),
    icon: "fa-duotone fa-warehouse",
    archived_at:,
    created_at: archived_at,
    updated_at: archived_at
  )
end

Rails.logger.info "E2E: Created notifications_bulk scenario test data"
