class PrefillOtpSecretForAllUsers < ActiveRecord::Migration[6.1]
  def up
    User.find_each do |user|
      next if user.otp_secret.present?

      user.otp_secret = User.generate_otp_secret
      user.save
    end

    AdminUser.find_each do |admin_user|
      next if admin_user.otp_secret.present?

      admin_user.otp_secret = AdminUser.generate_otp_secret
      admin_user.save
    end
  end
end
