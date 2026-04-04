# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminMailer do
  let!(:super_admin) { create(:admin_user, super_admin: true, email: "admin@fleetyards.test") }

  describe "#weekly" do
    let(:stats) do
      {
        registrations: 10,
        ships: 5,
        vehicles: 20,
        fleets: 2
      }
    end
    let(:mail) { described_class.weekly(stats) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.admin.weekly.subject"))
    end

    it "sends to super admin users" do
      expect(mail.to).to include(super_admin.email)
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#notify_block" do
    let(:url) { "https://robertsspaceindustries.com" }
    let(:mail) { described_class.notify_block(url) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.admin.notify_block.subject"))
    end

    it "sends to super admin users" do
      expect(mail.to).to include(super_admin.email)
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#notify_unblock" do
    let(:url) { "https://robertsspaceindustries.com" }
    let(:mail) { described_class.notify_unblock(url) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.admin.notify_block.subject"))
    end

    it "sends to super admin users" do
      expect(mail.to).to include(super_admin.email)
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
