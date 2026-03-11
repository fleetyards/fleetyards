# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailProcessor do
  describe "#process" do
    it "creates a message with attachment" do
      # rubocop:disable Style/OpenStructUse
      # rubocop:disable Performance/OpenStruct
      email = OpenStruct.new(
        to: [{full: "to_user@email.com", email: "to_user@email.com", token: "to_user", host: "email.com", name: nil}],
        from: {token: "from_user", host: "email.com", email: "from_email@email.com", full: "From User <from_user@email.com>", name: "From User"},
        subject: "email subject",
        body: "Hello!",
        attachments: [
          ActionDispatch::Http::UploadedFile.new(
            filename: "img.png",
            type: "image/png",
            tempfile: File.new(Rails.root.join("spec/fixtures/files/test.png"))
          )
        ]
      )
      # rubocop:enable Performance/OpenStruct
      # rubocop:enable Style/OpenStructUse

      processor = EmailProcessor.new(email)

      expect { processor.process }.to change(Message, :count).by(1)
        .and change(MessageAttachment, :count).by(1)
    end
  end
end
