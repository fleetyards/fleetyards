# frozen_string_literal: true

require "test_helper"

class FleetMembershipMailerTest < ActionMailer::TestCase
  setup do
    @fleet = create(:fleet)
  end

  test "#new_invite renders the subject" do
    mail = FleetMembershipMailer.new_invite("user@example.com", "testuser", @fleet)
    assert_equal I18n.t(:"mailer.fleet_membership.new_invite.subject"), mail.subject
  end

  test "#new_invite sends to the correct recipient" do
    mail = FleetMembershipMailer.new_invite("user@example.com", "testuser", @fleet)
    assert_equal ["user@example.com"], mail.to
  end

  test "#new_invite renders the body" do
    mail = FleetMembershipMailer.new_invite("user@example.com", "testuser", @fleet)
    assert mail.body.encoded.present?
  end

  test "#member_requested renders the subject" do
    mail = FleetMembershipMailer.member_requested("admin@example.com", "newmember", @fleet)
    assert_equal I18n.t(:"mailer.fleet_membership.member_requested.subject"), mail.subject
  end

  test "#member_requested sends to the correct recipient" do
    mail = FleetMembershipMailer.member_requested("admin@example.com", "newmember", @fleet)
    assert_equal ["admin@example.com"], mail.to
  end

  test "#member_requested renders the body" do
    mail = FleetMembershipMailer.member_requested("admin@example.com", "newmember", @fleet)
    assert mail.body.encoded.present?
  end

  test "#member_accepted renders the subject" do
    mail = FleetMembershipMailer.member_accepted("admin@example.com", "newmember", @fleet)
    assert_equal I18n.t(:"mailer.fleet_membership.member_accepted.subject"), mail.subject
  end

  test "#member_accepted sends to the correct recipient" do
    mail = FleetMembershipMailer.member_accepted("admin@example.com", "newmember", @fleet)
    assert_equal ["admin@example.com"], mail.to
  end

  test "#member_accepted renders the body" do
    mail = FleetMembershipMailer.member_accepted("admin@example.com", "newmember", @fleet)
    assert mail.body.encoded.present?
  end

  test "#fleet_accepted renders the subject with fleet name" do
    mail = FleetMembershipMailer.fleet_accepted("user@example.com", "testuser", @fleet)
    assert_equal I18n.t(:"mailer.fleet_membership.fleet_accepted.subject", fleet: @fleet.name), mail.subject
  end

  test "#fleet_accepted sends to the correct recipient" do
    mail = FleetMembershipMailer.fleet_accepted("user@example.com", "testuser", @fleet)
    assert_equal ["user@example.com"], mail.to
  end

  test "#fleet_accepted renders the body" do
    mail = FleetMembershipMailer.fleet_accepted("user@example.com", "testuser", @fleet)
    assert mail.body.encoded.present?
  end
end
