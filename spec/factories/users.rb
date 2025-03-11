# == Schema Information
#
# Table name: users
#
#  id                        :uuid             not null, primary key
#  avatar                    :string
#  confirmation_sent_at      :datetime
#  confirmation_token        :string(255)
#  confirmed_at              :datetime
#  consumed_timestep         :integer
#  current_sign_in_at        :datetime
#  current_sign_in_ip        :string(255)
#  discord                   :string
#  email                     :string(255)      default(""), not null
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  encrypted_password        :string(255)      default(""), not null
#  failed_attempts           :integer          default(0), not null
#  guilded                   :string
#  hangar_updated_at         :datetime
#  hide_owner                :boolean          default(FALSE), not null
#  homepage                  :string
#  last_active_at            :datetime
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  locale                    :string(255)
#  locked_at                 :datetime
#  normalized_email          :string
#  normalized_username       :string
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  otp_secret                :string
#  public_hangar             :boolean          default(TRUE)
#  public_hangar_loaners     :boolean          default(FALSE)
#  public_wishlist           :boolean          default(FALSE)
#  purchased_vehicles_count  :integer          default(0), not null
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  sale_notify               :boolean          default(FALSE)
#  sign_in_count             :integer          default(0), not null
#  tester                    :boolean          default(FALSE)
#  tracking                  :boolean          default(TRUE)
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  wanted_vehicles_count     :integer          default(0), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_normalized_username   (normalized_username)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
FactoryBot.define do
  factory :user do
    username { Faker::Internet.username(separators: ["_"]) }
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    password_confirmation { password }
    confirmed_at { Time.now }
  end
end
