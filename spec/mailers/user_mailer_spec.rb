# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer do
  describe "#username_changed" do
    let(:email) { "user@example.com" }
    let(:username) { "testuser" }
    let(:mail) { described_class.username_changed(email, username) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.user.username_changed.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
