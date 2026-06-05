# frozen_string_literal: true

require "test_helper"

class EmailProcessorTest < ActiveSupport::TestCase
  test "#process creates a message with attachment" do
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

    processor = EmailProcessor.new(email)

    assert_difference -> { Message.count } => 1, -> { MessageAttachment.count } => 1 do
      processor.process
    end
  end
end
