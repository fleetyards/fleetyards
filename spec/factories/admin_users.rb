# == Schema Information
#
# Table name: admin_users
#
#  id                        :uuid             not null, primary key
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  email                     :string(255)      default(""), not null
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  encrypted_password        :string(255)      default(""), not null
#  failed_attempts           :integer          default(0), not null
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  normalized_email          :string
#  normalized_username       :string
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  otp_secret                :string
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  resource_access           :string
#  sign_in_count             :integer          default(0), not null
#  super_admin               :boolean          default(FALSE)
#  username                  :string(255)      default(""), not null
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_admin_users_on_username              (username) UNIQUE
#
FactoryBot.define do
  factory :admin_user do
    username { Faker::Internet.username(separators: ["_"]) }
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    password_confirmation { password }
  end
end
