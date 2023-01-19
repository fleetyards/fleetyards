class AddOtpSecretToAdminUser < ActiveRecord::Migration[7.0]
  def change
    add_column :admin_users, :otp_secret, :string
  end
end
