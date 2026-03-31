# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactorMailer do
  describe "#login" do
    let(:email) { "user@example.com" }
    let(:token) { "123456" }
    let(:mail) { described_class.login(email, token) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.two_factor.login.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#enabled" do
    let(:email) { "user@example.com" }
    let(:username) { "testuser" }
    let(:mail) { described_class.enabled(email, username) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.two_factor.enabled.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#disabled" do
    let(:email) { "user@example.com" }
    let(:username) { "testuser" }
    let(:mail) { described_class.disabled(email, username) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.two_factor.disabled.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
