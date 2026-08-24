# frozen_string_literal: true

namespace :admin_notifications do
  desc "Fill the notification center with a spread of example notifications (never in production). ADMIN_USER=<username|email> narrows the recipients."
  task examples: :environment do
    abort "Refusing to create example notifications in production" if Rails.env.production?

    admin_users = AdminNotificationRecipients.find

    abort "No matching admin user found" if admin_users.empty?

    created = admin_users.sum { |admin_user| AdminNotificationExamples.create_for(admin_user) }

    puts "Created #{created} example notifications for #{admin_users.map(&:username).join(", ")}"
  end

  desc "Delete every notification of the admin users the examples task targets (never in production)."
  task clear: :environment do
    abort "Refusing to delete notifications in production" if Rails.env.production?

    admin_users = AdminNotificationRecipients.find

    abort "No matching admin user found" if admin_users.empty?

    deleted = AdminNotification.where(admin_user: admin_users).delete_all

    puts "Deleted #{deleted} notifications"
  end
end

module AdminNotificationRecipients
  module_function

  def find
    login = ENV["ADMIN_USER"].presence

    return AdminUser.all.to_a if login.nil?

    AdminUser.where(
      "normalized_username = :value OR normalized_email = :value",
      value: login.downcase
    ).to_a
  end
end
