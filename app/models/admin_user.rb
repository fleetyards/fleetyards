# frozen_string_literal: true

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
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  sign_in_count             :integer          default(0), not null
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
class AdminUser < ApplicationRecord
  devise :two_factor_authenticatable, :two_factor_backupable, :recoverable, :trackable, :validatable,
         :timeoutable, :rememberable,
         authentication_keys: [:username], otp_secret_encryption_key: Rails.application.secrets[:devise_admin_otp],
         otp_backup_code_length: 32, otp_number_of_backup_codes: 10
end
