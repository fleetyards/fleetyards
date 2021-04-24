# frozen_string_literal: true

# == Schema Information
#
# Table name: fleets
#
#  id               :uuid             not null, primary key
#  background_image :string
#  created_by       :uuid
#  description      :text
#  discord          :string
#  fid              :string
#  guilded          :string
#  homepage         :string
#  logo             :string
#  name             :string
#  public_fleet     :boolean          default(FALSE)
#  rsi_sid          :string
#  sid              :string
#  slug             :string
#  ts               :string
#  twitch           :string
#  youtube          :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_fleets_on_fid  (fid) UNIQUE
#
require 'test_helper'

class FleetTest < ActiveSupport::TestCase
  let(:klingon_empire) { fleets :klingon_empire }
  let(:url) { 'foo.bar' }
  let(:url_slash) { '//foo.bar' }
  let(:url_http) { 'http://foo.bar' }
  let(:url_https) { 'https://foo.bar' }
  let(:expected_url) { 'foo.bar' }
  let(:expected_ts_url) { 'ts3server://foo.bar' }

  test 'ensure valid urls are saved' do
    klingon_empire.update(
      guilded: url,
      homepage: url,
      discord: url,
      twitch: url,
      youtube: url
    )

    klingon_empire.reload

    assert_equal(expected_url, klingon_empire.guilded)
    assert_equal(expected_url, klingon_empire.homepage)
    assert_equal(expected_url, klingon_empire.discord)
    assert_equal(expected_url, klingon_empire.twitch)
    assert_equal(expected_url, klingon_empire.youtube)
  end

  test 'ensure valid urls are saved with slashes' do
    klingon_empire.update(
      guilded: url_slash,
      homepage: url_slash,
      discord: url_slash,
      twitch: url_slash,
      youtube: url_slash
    )

    klingon_empire.reload

    assert_equal(expected_url, klingon_empire.guilded)
    assert_equal(expected_url, klingon_empire.homepage)
    assert_equal(expected_url, klingon_empire.discord)
    assert_equal(expected_url, klingon_empire.twitch)
    assert_equal(expected_url, klingon_empire.youtube)
  end

  test 'ensure valid urls are saved with http' do
    klingon_empire.update(
      guilded: url_http,
      homepage: url_http,
      discord: url_http,
      twitch: url_http,
      youtube: url_http
    )

    klingon_empire.reload

    assert_equal(expected_url, klingon_empire.guilded)
    assert_equal(expected_url, klingon_empire.homepage)
    assert_equal(expected_url, klingon_empire.discord)
    assert_equal(expected_url, klingon_empire.twitch)
    assert_equal(expected_url, klingon_empire.youtube)
  end

  test 'ensure valid urls are saved with https' do
    klingon_empire.update(
      guilded: url_https,
      homepage: url_https,
      discord: url_https,
      twitch: url_https,
      youtube: url_https
    )

    klingon_empire.reload

    assert_equal(expected_url, klingon_empire.guilded)
    assert_equal(expected_url, klingon_empire.homepage)
    assert_equal(expected_url, klingon_empire.discord)
    assert_equal(expected_url, klingon_empire.twitch)
    assert_equal(expected_url, klingon_empire.youtube)
  end

  test 'ensure valid ts url' do
    klingon_empire.update(ts: url)

    klingon_empire.reload

    assert_equal(expected_ts_url, klingon_empire.ts)
  end

  test 'ensure valid ts url with slash' do
    klingon_empire.update(ts: url_slash)

    klingon_empire.reload

    assert_equal(expected_ts_url, klingon_empire.ts)
  end

  test 'ensure valid ts url with http' do
    klingon_empire.update(ts: url_http)

    klingon_empire.reload

    assert_equal(expected_ts_url, klingon_empire.ts)
  end

  test 'ensure valid ts url with https' do
    klingon_empire.update(ts: url_https)

    klingon_empire.reload

    assert_equal(expected_ts_url, klingon_empire.ts)
  end
end
