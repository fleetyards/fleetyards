# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModelMailer do
  describe "#notify_new" do
    let(:email) { "user@example.com" }
    let(:model) { create(:model) }
    let(:mail) { described_class.notify_new(email, model) }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t(:"mailer.model.new.subject"))
    end

    it "sends to the correct recipient" do
      expect(mail.to).to eq([email])
    end

    it "sets the broadcast message stream" do
      expect(mail["message_stream"].value).to eq("broadcast")
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
