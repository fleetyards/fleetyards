# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetMembershipMailer do
  let(:fleet) { create(:fleet) }

  describe "#new_invite" do
    let(:email) { "user@example.com" }
    let(:username) { "testuser" }
    let(:mail) { described_class.new_invite(email, username, fleet) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.fleet_membership.new_invite.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#member_requested" do
    let(:email) { "admin@example.com" }
    let(:member_username) { "newmember" }
    let(:mail) { described_class.member_requested(email, member_username, fleet) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.fleet_membership.member_requested.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#member_accepted" do
    let(:email) { "admin@example.com" }
    let(:member_username) { "newmember" }
    let(:mail) { described_class.member_accepted(email, member_username, fleet) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.fleet_membership.member_accepted.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#fleet_accepted" do
    let(:email) { "user@example.com" }
    let(:username) { "testuser" }
    let(:mail) { described_class.fleet_accepted(email, username, fleet) }

    it "renders the subject with fleet name" do
      expect(mail.subject).to eq(I18n.t(:"mailer.fleet_membership.fleet_accepted.subject", fleet: fleet.name))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
