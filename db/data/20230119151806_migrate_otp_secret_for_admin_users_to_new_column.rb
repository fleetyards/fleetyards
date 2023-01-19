# frozen_string_literal: true

class MigrateOtpSecretForAdminUsersToNewColumn < ActiveRecord::Migration[7.0]
  def up
    bar = ProgressBar.new(AdminUser.count)

    AdminUser.find_each do |admin_user|
      otp_secret = admin_user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty

      admin_user.update!(otp_secret: otp_secret)

      bar.increment!
    end
  end

  def down
  end
end
