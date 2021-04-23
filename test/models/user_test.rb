# frozen_string_literal: true

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
#  homepage                  :string
#  last_sign_in_at           :datetime
#  last_sign_in_ip           :string(255)
#  locale                    :string(255)
#  locked_at                 :datetime
#  otp_backup_codes          :string           is an Array
#  otp_required_for_login    :boolean
#  public_hangar             :boolean          default(TRUE)
#  remember_created_at       :datetime
#  reset_password_sent_at    :datetime
#  reset_password_token      :string(255)
#  rsi_handle                :string
#  sale_notify               :boolean          default(FALSE)
#  sign_in_count             :integer          default(0), not null
#  tracking                  :boolean          default(TRUE)
#  twitch                    :string
#  unconfirmed_email         :string(255)
#  unlock_token              :string(255)
#  username                  :string(255)      default(""), not null
#  youtube                   :string
#  created_at                :datetime
#  updated_at                :datetime
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  let(:user_data) { users :data }
  let(:url) { 'foo.bar' }
  let(:url_slash) { '//foo.bar' }
  let(:url_http) { 'http://foo.bar' }
  let(:url_https) { 'https://foo.bar' }
  let(:expected_url) { '//foo.bar' }
  let(:expected_ts_url) { 'ts3server://foo.bar' }

  test 'ensure valid urls are saved' do
    user_data.update(
      guilded: url,
      homepage: url,
      discord: url,
      twitch: url,
      youtube: url
    )

    user_data.reload

    assert_equal(expected_url, user_data.guilded)
    assert_equal(expected_url, user_data.homepage)
    assert_equal(expected_url, user_data.discord)
    assert_equal(expected_url, user_data.twitch)
    assert_equal(expected_url, user_data.youtube)
  end

  test 'ensure valid urls are saved with slashes' do
    user_data.update(
      guilded: url_slash,
      homepage: url_slash,
      discord: url_slash,
      twitch: url_slash,
      youtube: url_slash
    )

    user_data.reload

    assert_equal(expected_url, user_data.guilded)
    assert_equal(expected_url, user_data.homepage)
    assert_equal(expected_url, user_data.discord)
    assert_equal(expected_url, user_data.twitch)
    assert_equal(expected_url, user_data.youtube)
  end

  test 'ensure valid urls are saved with http' do
    user_data.update(
      guilded: url_http,
      homepage: url_http,
      discord: url_http,
      twitch: url_http,
      youtube: url_http
    )

    user_data.reload

    assert_equal(expected_url, user_data.guilded)
    assert_equal(expected_url, user_data.homepage)
    assert_equal(expected_url, user_data.discord)
    assert_equal(expected_url, user_data.twitch)
    assert_equal(expected_url, user_data.youtube)
  end

  test 'ensure valid urls are saved with https' do
    user_data.update(
      guilded: url_https,
      homepage: url_https,
      discord: url_https,
      twitch: url_https,
      youtube: url_https
    )

    user_data.reload

    assert_equal(expected_url, user_data.guilded)
    assert_equal(expected_url, user_data.homepage)
    assert_equal(expected_url, user_data.discord)
    assert_equal(expected_url, user_data.twitch)
    assert_equal(expected_url, user_data.youtube)
  end
end
